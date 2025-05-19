constants = import_module("./src/package_io/constants.star")
input_parser = import_module("./input_parser.star")
service_package = import_module("./lib/service.star")

# Main service packages.
additional_services = import_module("./src/additional_services/launcher.star")
agglayer_package = "./agglayer.star"
cdk_bridge_infra_package = "./cdk_bridge_infra.star"
cdk_central_environment_package = "./cdk_central_environment.star"
aggkit_package = "./aggkit.star"
cdk_erigon_package = "./cdk_erigon.star"
databases_package = "./databases.star"
deploy_zkevm_contracts_package = "./deploy_zkevm_contracts.star"
ethereum_package = "./ethereum.star"
anvil_package = "./anvil.star"
zkevm_pool_manager_package = "./zkevm_pool_manager.star"
deploy_l2_contracts_package = "./deploy_l2_contracts.star"
deploy_sovereign_contracts_package = "./deploy_sovereign_contracts.star"
create_sovereign_predeployed_genesis_package = (
    "./create_sovereign_predeployed_genesis.star"
)
mitm_package = "./mitm.star"
op_succinct_package = "./op_succinct.star"


def run(plan, args={}):
    # Parse args.
    (deployment_stages, args, op_stack_args) = input_parser.parse_args(plan, args)
    plan.print("Deploying the following components: " + str(deployment_stages))
    verbosity = args.get("verbosity", "")
    if verbosity == constants.LOG_LEVEL.debug or verbosity == constants.LOG_LEVEL.trace:
        plan.print("Deploying CDK stack with the following configuration: " + str(args))

    # Deploy Contracts on L1.
    contract_setup_addresses = {}
    # Deploy cdk-erigon node.
    if deployment_stages.get("deploy_cdk_erigon_node", False):
        plan.print("Deploying cdk-erigon node")
        import_module(cdk_erigon_package).run_rpc(
            plan,
            args
            | {
                "l1_rpc_url": args["mitm_rpc_url"].get(
                    "erigon-rpc", args["l1_rpc_url"]
                )
            },
            contract_setup_addresses,
            )
    else:
        plan.print("Skipping the deployment of cdk-erigon node")


def deploy_helper_service(plan, args):
    # Create script artifact.
    get_rollup_info_template = read_file(src="./templates/get-rollup-info.sh")
    get_rollup_info_artifact = plan.render_templates(
        name="get-rollup-info-artifact",
        config={
            "get-rollup-info.sh": struct(
                template=get_rollup_info_template,
                data=args
                | {
                    "rpc_url": args["l1_rpc_url"],
                },
            )
        },
    )

    # Deploy helper service.
    helper_service_name = "helper" + args["deployment_suffix"]
    plan.add_service(
        name=helper_service_name,
        config=ServiceConfig(
            image=constants.TOOLBOX_IMAGE,
            files={"/opt/zkevm": get_rollup_info_artifact},
            # These two lines are only necessary to deploy to any Kubernetes environment (e.g. GKE).
            entrypoint=["bash", "-c"],
            cmd=["sleep infinity"],
        ),
    )

    # Retrieve rollup data.
    plan.exec(
        description="Retrieving rollup data from the rollup manager contract",
        service_name=helper_service_name,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "chmod +x {0} && {0}".format(
                    "/opt/zkevm/get-rollup-info.sh",
                ),
            ]
        ),
    )
