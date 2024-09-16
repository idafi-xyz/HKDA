import {
    time,
    loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";

describe("TokenPermissions",function(){

    const complianceErrMsg = "Permissions: Only compliance team call this method";
    const operatorErrMsg = "Permissions: Only operator team call this method";
    const pausableErrMsg = "Pausable: paused";

    async function deployStableCoinTokenLogic() {
        const [proxyAdmin,compliance, operator] = await hre.ethers.getSigners();
        const sToken = await hre.ethers.getContractFactory("StablecoinToken");
        const tokenLogic = await sToken.deploy();

        return { tokenLogic,sToken };
    }

    async function deployStableCoinProxy() {
        const name = "StableCoinToken";
        const symbol = "SCT";
        const currency = "HSCT";
        const decimals = 18

        // Contracts are deployed using the first signer/account by default
        const [proxyAdmin,compliance, operator] = await hre.ethers.getSigners();

        const {tokenLogic} = await loadFixture(deployStableCoinTokenLogic);
        
        //token.initialize(name, symbol, currency, decimals, compliance.address, operator.address);
        const tProxy = await hre.ethers.getContractFactory("TransparentUpgradeableProxy");
        const input = tokenLogic.interface.encodeFunctionData("initialize",[name, symbol, currency, decimals, compliance.address, operator.address,"0x0000000000000000000000000000000000000001",true]);

        const proxy = await tProxy.deploy(tokenLogic.getAddress(),proxyAdmin.address,input);

        const token = await hre.ethers.getContractAt("StablecoinToken",await proxy.getAddress(),compliance);

        return { token,proxyAdmin,compliance, operator };
    }

    async function getToken() {
        const thatUser = (await hre.ethers.getSigners())[3];

        const { token, compliance ,operator} = await loadFixture(deployStableCoinProxy);
        const thatToken = await hre.ethers.getContractAt("StablecoinToken",await token.getAddress(),thatUser);

        const complianceToken = await hre.ethers.getContractAt("StablecoinToken",await token.getAddress(),compliance);
        const operatorToken = await hre.ethers.getContractAt("StablecoinToken",await token.getAddress(),operator);

        return {thatToken,complianceToken,operatorToken};
    }

    describe("compliance",function(){

        it("Should compliance permissions address",async function () {
            const { token, compliance ,operator} = await loadFixture(deployStableCoinProxy);

             expect(await token.compliance()).to.be.equal(compliance);
        });
       
        it("Should update compliance permissions",async function () {

            const {thatToken} =await loadFixture(getToken);
            const compliance = (await hre.ethers.getSigners())[4];
            await expect(thatToken.updateCompliance(compliance)).to.be.revertedWith(complianceErrMsg);

        });

        it("Should pause permissions",async function () {

            const {thatToken} =await loadFixture(getToken);
        
            await expect(thatToken.pause()).to.be.revertedWith(complianceErrMsg);
        });
        
        it("Should unpause permissions",async function () {

            const {thatToken} =await loadFixture(getToken);
        
            await expect(thatToken.unpause()).to.be.revertedWith(complianceErrMsg);
        });

        it("Should freeze permissions",async function () {

            const {thatToken,complianceToken} =await loadFixture(getToken);
            const account = (await hre.ethers.getSigners())[4];

            await expect(thatToken.freeze(account)).to.be.revertedWith(complianceErrMsg);
            
            complianceToken.pause();
            expect(await complianceToken.paused()).to.be.equal(false);
            await expect(complianceToken.freeze(account)).to.be.revertedWith(pausableErrMsg);

        });

        it("Should unFreeze permissions",async function () {

            const {thatToken,complianceToken} =await loadFixture(getToken);
            const account = (await hre.ethers.getSigners())[4];
            await expect(thatToken.unFreeze(account)).to.be.revertedWith(complianceErrMsg);

            complianceToken.pause();
            expect(await complianceToken.paused()).to.be.equal(false);
            await expect(complianceToken.unFreeze(account)).to.be.revertedWith(pausableErrMsg);
        });

        it("Should whitelist permissions",async function () {

            const {thatToken,complianceToken} =await loadFixture(getToken);
            const account = (await hre.ethers.getSigners())[4];
            await expect(thatToken.whitelist(account)).to.be.revertedWith(complianceErrMsg);

            complianceToken.pause();
            expect(await complianceToken.paused()).to.be.equal(false);
            await expect(complianceToken.whitelist(account)).to.be.revertedWith(pausableErrMsg);
        });

        it("Should unWhitelist permissions",async function () {

            const {thatToken,complianceToken} =await loadFixture(getToken);
            const account = (await hre.ethers.getSigners())[4];
            await expect(thatToken.unWhitelist(account)).to.be.revertedWith(complianceErrMsg);

            complianceToken.pause();
            expect(await complianceToken.paused()).to.be.equal(false);
            await expect(complianceToken.unWhitelist(account)).to.be.revertedWith(pausableErrMsg);
        });

        it("Should disableWhitelisted permissions",async function () {

            const {thatToken,complianceToken} =await loadFixture(getToken);

            await expect(thatToken.disableWhitelisted()).to.be.revertedWith(complianceErrMsg);

            complianceToken.pause();
            expect(await complianceToken.paused()).to.be.equal(false);
            await expect(complianceToken.disableWhitelisted()).to.be.revertedWith(pausableErrMsg);
        });

        it("Should enableWhitelisted permissions",async function () {

            const {thatToken,complianceToken} =await loadFixture(getToken);

            await expect(thatToken.enableWhitelisted()).to.be.revertedWith(complianceErrMsg);

            complianceToken.pause();
            expect(await complianceToken.paused()).to.be.equal(false);
            await expect(complianceToken.enableWhitelisted()).to.be.revertedWith(pausableErrMsg);
        });

        it("Should rescue NativeCurrency permissions",async function () {

            const {thatToken,complianceToken} =await loadFixture(getToken);
            
            const to =  (await hre.ethers.getSigners())[5];
        
            await expect(thatToken.rescueNativeCurrency(to,100)).to.be.revertedWith(complianceErrMsg);

            complianceToken.pause();
            expect(await complianceToken.paused()).to.be.equal(false);
            await expect(complianceToken.rescueNativeCurrency(to,100)).to.be.revertedWith(pausableErrMsg);
        });

        it("Should rescue ERC20 permissions",async function () {

            const {thatToken,complianceToken} =await loadFixture(getToken);
            
            const erc20Address = (await hre.ethers.getSigners())[4];
            const to =  (await hre.ethers.getSigners())[5];
        
            await expect(thatToken.rescueERC20(erc20Address,to,100)).to.be.revertedWith(complianceErrMsg);

            complianceToken.pause();
            expect(await complianceToken.paused()).to.be.equal(false);
            await expect(complianceToken.rescueERC20(erc20Address,to,100)).to.be.revertedWith(pausableErrMsg);
        });

        it("Should updateReserveBalance permissions",async function () {

            const {thatToken,complianceToken} =await loadFixture(getToken);
            
            await expect(thatToken.updateReserveBalance(100)).to.be.revertedWith(complianceErrMsg);

            complianceToken.pause();
            expect(await complianceToken.paused()).to.be.equal(false);
            await expect(complianceToken.updateReserveBalance(100)).to.be.revertedWith(pausableErrMsg);
        });

        it("Should seizeTransferFrom permissions",async function () {

            const {thatToken,complianceToken} =await loadFixture(getToken);

            const from = (await hre.ethers.getSigners())[4];
            const to =  (await hre.ethers.getSigners())[5];
            
            await expect(thatToken.seizeTransferFrom(from,to,100)).to.be.revertedWith(complianceErrMsg);

            complianceToken.pause();
            expect(await complianceToken.paused()).to.be.equal(false);
            await expect(complianceToken.seizeTransferFrom(from,to,100)).to.be.revertedWith(pausableErrMsg);
        });

        it("Should updateBurnAccount permissions",async function () {

            const {thatToken,complianceToken} =await loadFixture(getToken);

            const account = (await hre.ethers.getSigners())[4];
            
            await expect(thatToken.updateBurnAccount(account)).to.be.revertedWith(complianceErrMsg);

            complianceToken.pause();
            expect(await complianceToken.paused()).to.be.equal(false);
            await expect(complianceToken.updateBurnAccount(account)).to.be.revertedWith(pausableErrMsg);
        });
    });

    describe("operator",function(){

        it("Should operator permissions address",async function () {
            const { token, compliance ,operator} = await loadFixture(deployStableCoinProxy);

             expect(await token.operator()).to.be.equal(operator);
        });

        it("Should update operator permissions",async function () {

            const {thatToken} =await loadFixture(getToken);
            const operator = (await hre.ethers.getSigners())[4];
            await expect(thatToken.updateOperator(operator)).to.be.revertedWith(operatorErrMsg);

        });

        it("Should mint permissions",async function () {

            const {thatToken,complianceToken,operatorToken} =await loadFixture(getToken);
            const to = (await hre.ethers.getSigners())[4];

            complianceToken.whitelist(to);

            await expect(thatToken.mint(to,100)).to.be.revertedWith(operatorErrMsg);
            
            complianceToken.pause();
            expect(await complianceToken.paused()).to.be.equal(false);

            await expect(operatorToken.mint(to,100)).to.be.revertedWith(pausableErrMsg);

        });

        it("Should burn permissions",async function () {

            const {thatToken,complianceToken,operatorToken} =await loadFixture(getToken);
            const to = (await hre.ethers.getSigners())[4];

            await expect(thatToken.burn(100)).to.be.revertedWith(operatorErrMsg);
            
            complianceToken.pause();
            expect(await complianceToken.paused()).to.be.equal(false);

            await expect(operatorToken.burn(100)).to.be.revertedWith(pausableErrMsg);

        });
    });

});