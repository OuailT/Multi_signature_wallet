// Test transactions that should fail
const chai = require("chai");
chai.use(require("chai-as-promised"));
const expect = chai.expect;

// We tell truffle with contract we want to interact with
const MultiSignWallet = artifacts.require("MultiSignWallet");


contract("MultiSignWallet", accounts => {
    // get accounts + confirmation required
    const owners = [accounts[0], accounts[1], accounts[2]];
    const NUM_CONFIRMATION_REQUIRED = 2;

    let wallet;
    // to run this code each time we run the test (create wallet)
    beforeEach(async()=> {
        wallet = await MultiSignWallet.new(owners,NUM_CONFIRMATION_REQUIRED);
    });


    describe("Execute transaction", async ()=> {

    beforeEach(async()=> {
        const to = owners[0];
        const value = 0;
        const data = 0x14;

        await wallet.submitTransactions(to, value, data);
        await wallet.confirmTransaction(0, {from : owners[0]});
        await wallet.confirmTransaction(0,{from: owners[1]});
    });

    // execute transaction should succeed
    it("should execute", async ()=> {
        const res = await wallet.executeTransaction(0, {from: owners[0]});
        
        // Destruct logs from the res objects
        const { logs } = res;

        // We should check if the event has been emitted
        assert.equal(logs[0].event, "ExecuteTransaction");
        assert.equal(logs[0].args.owner, owners[0], "address is not correct");
        assert.equal(logs[0].args.txIndex, 0);

        // Check the the transaction.Executed is true.
        const tx = await wallet.getTransaction(0);

        assert.equal(tx.executed, true);
    });

    it("should not be executed", async ()=> {
        await wallet.executeTransaction(0, {from: owners[0]});

        // check if executeTransaction is failing after we call it twice, since we re testing a promise so..
        await expect(wallet.executeTransaction(0, {from: owners[0]})).to.be.rejected
    });

 });

});