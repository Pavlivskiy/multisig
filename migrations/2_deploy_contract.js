var MultiSig = artifacts.require("./MultiSig.sol");

module.exports = function(deployer, network, accounts) {
    deployer.deploy(MultiSig, accounts[0], accounts[1], accounts[2]);
};
