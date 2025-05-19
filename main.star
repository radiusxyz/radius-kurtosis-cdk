constants = import_module("./src/package_io/constants.star")
input_parser = import_module("./input_parser.star")
cdk_erigon_package = "./cdk_erigon.star"

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