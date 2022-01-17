
const MultiSignWallet = artifacts.require("MultiSignWallet");

module.exports = function(deployer, network, accounts) {
    const owners = accounts.slice(0,3);
    const numConfirmationsRequired= 2;
    
    deployer.deploy(MultiSignWallet,owners,numConfirmationsRequired);
}


