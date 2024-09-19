import {
    time,
    loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";


describe("StableCoinToken", function () {

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

    async function tokenByCompliance() {
        const { token, compliance } = await loadFixture(deployStableCoinProxy);
        const complianceToken = await hre.ethers.getContractAt("StablecoinToken",await token.getAddress(),compliance);
        return complianceToken;
    }

    async function tokenByOperator() {
        const { token, operator } = await loadFixture(deployStableCoinProxy);
        const operatorToken = await hre.ethers.getContractAt("StablecoinToken",await token.getAddress(),operator);
        return operatorToken;
    }

    async function tokenByBurner() {
        const { token, operator } = await loadFixture(deployStableCoinProxy);
        
        const user = (await hre.ethers.getSigners())[5];
        const burnerToken = await hre.ethers.getContractAt("StablecoinToken",await token.getAddress(),user);
        return burnerToken;
    }
    describe("Whitelist",function(){


        it("Should whitelist status",async function () {

            const complianceToken = await tokenByCompliance();
            expect(await complianceToken.whitelistedStatus()).to.equal(true);
            await complianceToken.disableWhitelisted();
            expect(await complianceToken.whitelistedStatus()).to.equal(false);
            await complianceToken.enableWhitelisted();
            expect(await complianceToken.whitelistedStatus()).to.equal(true);

        });

        it("Should set whitelist",async function () {
            const complianceToken = await tokenByCompliance();
            const user = (await hre.ethers.getSigners())[4];
            
            await complianceToken.whitelist(user.address);
            expect(await complianceToken.isWhitelisted(user.address)).to.equal(true);
            await complianceToken.unWhitelist(user.address);
            expect(await complianceToken.isWhitelisted(user.address)).to.equal(false);

        });

    });

    describe("Freeze",function (){
        it("Should set Freeze",async function () {
            const complianceToken = await tokenByCompliance();
            const user = (await hre.ethers.getSigners())[4];

            await complianceToken.freeze(user.address);
            expect(await complianceToken.isFrozen(user.address)).to.equal(true);
            await complianceToken.unFreeze(user.address);
            expect(await complianceToken.isFrozen(user.address)).to.equal(false);
        });
    });

    describe("Stablecoin",function (){
        
        it("Should set Reserve Balance ",async function () {

            const complianceToken = await tokenByCompliance();
            
            await complianceToken.updateReserveBalance(100000n);

            expect(await complianceToken.reserveBalance()).to.equal(100000n);
        });

        it("Should mint amount to address ",async function () {

            
            const complianceToken = await tokenByCompliance();

            const operatorToken = await tokenByOperator();
            
            
            await complianceToken.updateReserveBalance(100000n);

            const user = (await hre.ethers.getSigners())[5];
            await complianceToken.whitelist(user.address);

            await operatorToken.mint(user.address, 100n);
            expect(await complianceToken.balanceOf(user.address)).to.equal(100n);
        });

        it("Should fail if Reserve balance limit ",async function () {
            const complianceToken = await tokenByCompliance();

            const operatorToken = await tokenByOperator();
            
            await complianceToken.updateReserveBalance(100000n);

            const user = (await hre.ethers.getSigners())[5];
            await complianceToken.whitelist(user.address);

            await expect( operatorToken.mint(user.address, 100100)).to.be.revertedWith("StableToken:reserve balance limit");
        });


        it("Should transfer amount to address ",async function () {

            
            const complianceToken = await tokenByCompliance();

            const operatorToken = await tokenByOperator();
            const burnerToken = await tokenByBurner();
            
            const { token, operator } = await loadFixture(deployStableCoinProxy);
            
            await complianceToken.updateReserveBalance(100000n);

            const user = (await hre.ethers.getSigners())[5];
            await complianceToken.whitelist(user.address);
            await complianceToken.whitelist(operator.address);

            await operatorToken.mint(user.address, 100n);
            await burnerToken.transfer(operator.address, 50n);
            expect(await complianceToken.balanceOf(user.address)).to.equal(50n);
            expect(await complianceToken.balanceOf(operator.address)).to.equal(50n);
        });


        it("Should fail if transfer amount exceeds balance",async function () {

            
            const complianceToken = await tokenByCompliance();

            const operatorToken = await tokenByOperator();
            const burnerToken = await tokenByBurner();
            
            const { token, operator } = await loadFixture(deployStableCoinProxy);
            
            await complianceToken.updateReserveBalance(100000n);

            const user = (await hre.ethers.getSigners())[5];
            await complianceToken.whitelist(user.address);
            await complianceToken.whitelist(operator.address);

            await operatorToken.mint(user.address, 100n);
            await expect(burnerToken.transfer(operator.address, 150n)).to.be.revertedWith("ERC20: transfer amount exceeds balance");
        });
        

        it("Should fail transferFrom if insufficient allowance ",async function () {

            const complianceToken = await tokenByCompliance();

            const operatorToken = await tokenByOperator();
            const burnerToken = await tokenByBurner();
            
            const { token, compliance, operator } = await loadFixture(deployStableCoinProxy);
            
            await complianceToken.updateReserveBalance(100000n);

            const user = (await hre.ethers.getSigners())[5];
            await complianceToken.whitelist(compliance.address);
            await complianceToken.whitelist(operator.address);
            await complianceToken.whitelist(user.address);

            await complianceToken.approve(user.address,1000n);
            
            expect(await complianceToken.allowance(compliance.address, user.address)).to.equal(1000n);
            await operatorToken.mint(compliance.address, 100n);
            await expect(complianceToken.transferFrom(user.address, operator.address, 1100n)).to.be.revertedWith("ERC20: insufficient allowance");
        });
        
        it("Should transferFrom amount to address ",async function () {

            const complianceToken = await tokenByCompliance();

            const operatorToken = await tokenByOperator();
            const burnerToken = await tokenByBurner();
            
            const { token, compliance, operator } = await loadFixture(deployStableCoinProxy);
            
            await complianceToken.updateReserveBalance(100000n);

            const user = (await hre.ethers.getSigners())[5];
            await complianceToken.whitelist(compliance.address);
            await complianceToken.whitelist(operator.address);
            await complianceToken.whitelist(user.address);

            await complianceToken.approve(user.address,1000n);
            
            await operatorToken.mint(compliance.address, 100n);
            await burnerToken.transferFrom(compliance.address, user.address, 50n);
            expect(await complianceToken.balanceOf(user.address)).to.equal(50n);
            expect(await complianceToken.balanceOf(compliance.address)).to.equal(50n);
        });
        

        it("Should seizeTransferFrom amount to address ",async function () {

            const complianceToken = await tokenByCompliance();

            const operatorToken = await tokenByOperator();
            const burnerToken = await tokenByBurner();
            
            const { token, operator } = await loadFixture(deployStableCoinProxy);
            
            await complianceToken.updateReserveBalance(100000n);

            const user = (await hre.ethers.getSigners())[5];
            await complianceToken.whitelist(user.address);

            await operatorToken.mint(user.address, 100n);
            
            await complianceToken.seizeTransferFrom(user.address, operator.address, 50n);
            expect(await complianceToken.balanceOf(user.address)).to.equal(50n);
            expect(await complianceToken.balanceOf(operator.address)).to.equal(50n);
        });

        it("Should burn amount to address ",async function () {
            const complianceToken = await tokenByCompliance();
            const operatorToken = await tokenByOperator();
            const burnerToken = await tokenByBurner();
            const burnAccount = "0x0000000000000000000000000000000000000001";
            const { token, operator } = await loadFixture(deployStableCoinProxy);
            
            await complianceToken.updateReserveBalance(100000n);

            const user = (await hre.ethers.getSigners())[5];
            await complianceToken.whitelist(user.address);

            await operatorToken.mint(user.address, 100n);
            await burnerToken.transfer(burnAccount, 50n);
            await operatorToken.burn(10n);
            expect(await complianceToken.balanceOf(user.address)).to.equal(50n);
            expect(await complianceToken.balanceOf(burnAccount)).to.equal(40n);
        });

        it("Should fail if burn amount exceeds balance ",async function () {
            const complianceToken = await tokenByCompliance();
            const operatorToken = await tokenByOperator();
            const burnerToken = await tokenByBurner();
            const { token, operator } = await loadFixture(deployStableCoinProxy);
            const burnAccount = "0x0000000000000000000000000000000000000001";
            await complianceToken.updateReserveBalance(100000n);

            const user = (await hre.ethers.getSigners())[5];
            await complianceToken.whitelist(user.address);

            await operatorToken.mint(user.address, 100n);
            await burnerToken.transfer(burnAccount, 50n);
            
            await expect(operatorToken.burn(60n)).to.be.revertedWith("ERC20: burn amount exceeds balance");
        });

        it("Should approve amount to spender",async function () {
            const complianceToken = await tokenByCompliance();
            const { token, compliance } = await loadFixture(deployStableCoinProxy);
            
            const user = (await hre.ethers.getSigners())[6];

            await complianceToken.whitelist(compliance.address);
            await complianceToken.whitelist(user.address);

            await complianceToken.approve(user.address,1000n);
            
            expect(await complianceToken.allowance(compliance.address,user.address)).to.equal(1000n);
        });

        it("Should get allowance ",async function () {
            const complianceToken = await tokenByCompliance();
            const { token, compliance } = await loadFixture(deployStableCoinProxy);
            
            const user = (await hre.ethers.getSigners())[6];

            await complianceToken.whitelist(compliance.address);
            await complianceToken.whitelist(user.address);

            await complianceToken.approve(user.address,1000n);
            
            expect(await complianceToken.allowance(compliance.address,user.address)).to.equal(1000n);
        });

        it("Should increase allowance to spender",async function () {
            const complianceToken = await tokenByCompliance();
            const { token, compliance } = await loadFixture(deployStableCoinProxy);
            
            const user = (await hre.ethers.getSigners())[6];
            await complianceToken.whitelist(compliance.address);
            await complianceToken.whitelist(user.address);

            await complianceToken.approve(user.address,1000n);

            await complianceToken.increaseAllowance(user.address,500n);
            expect(await complianceToken.allowance(compliance.address,user.address)).to.equal(1500n);
        });

        it("Should decrease allowance to spender",async function () {
            const complianceToken = await tokenByCompliance();
            const { token, compliance } = await loadFixture(deployStableCoinProxy);
            
            const user = (await hre.ethers.getSigners())[6];
            await complianceToken.whitelist(compliance.address);
            await complianceToken.whitelist(user.address);

            await complianceToken.approve(user.address,1000n);

            await complianceToken.decreaseAllowance(user.address,500n);
            expect(await complianceToken.allowance(compliance.address,user.address)).to.equal(500n);
        });
        
        it("Should get totalSupply",async function () {
            const complianceToken = await tokenByCompliance();
            expect(await complianceToken.totalSupply()).to.equal(0n);


            const operatorToken = await tokenByOperator();
            await complianceToken.updateReserveBalance(100000n);

            const user = (await hre.ethers.getSigners())[5];
            await complianceToken.whitelist(user.address);

            await operatorToken.mint(user.address, 100n);
            expect(await complianceToken.totalSupply()).to.equal(100n);
        });

        it("Should get balance",async function () {
            
            const complianceToken = await tokenByCompliance();

            const operatorToken = await tokenByOperator();
            
            
            await complianceToken.updateReserveBalance(100000n);

            const user = (await hre.ethers.getSigners())[5];
            await complianceToken.whitelist(user.address);

            await operatorToken.mint(user.address, 100n);
            expect(await complianceToken.balanceOf(user.address)).to.equal(100n);
        });

        it("Should get name",async function () {
            const complianceToken = await tokenByCompliance();
            expect(await complianceToken.name()).to.equal('StableCoinToken');
        });

        it("Should get symbol",async function () {
            const complianceToken = await tokenByCompliance();
            expect(await complianceToken.symbol()).to.equal('SCT');
        });

        it("Should get currency",async function () {
            const complianceToken = await tokenByCompliance();
            expect(await complianceToken.currency()).to.equal('HSCT');
        });

        it("Should get decimals",async function () {
            const complianceToken = await tokenByCompliance();
            expect(await complianceToken.decimals()).to.equal(18);
        });


    });


    describe("Permission",function(){


        it("Should update compliance",async function () {
            const complianceToken = await tokenByCompliance();
           
            const user = (await hre.ethers.getSigners())[5];
            await complianceToken.updateCompliance(user.address);
            expect(await complianceToken.compliance()).to.equal(user.address);
        });

        it("Should get compliance",async function () {
            const complianceToken = await tokenByCompliance();
           
            const user = (await hre.ethers.getSigners())[5];
            await complianceToken.updateCompliance(user.address);
            expect(await complianceToken.compliance()).to.equal(user.address);
        });
        

        it("Should fail if caller is not operator",async function () {
            const complianceToken = await tokenByCompliance();
           
            const user = (await hre.ethers.getSigners())[5];
            await expect(complianceToken.updateOperator(user.address)).to.be.revertedWith("Permissions: Only operator team call this method");
        });
        it("Should update operator",async function () {
            const complianceToken = await tokenByCompliance();
            const operatorToken = await tokenByOperator();
            const user = (await hre.ethers.getSigners())[5];
            await operatorToken.updateOperator(user.address);
            expect(await complianceToken.operator()).to.equal(user.address);
        });
        it("Should get operator",async function () {
            const complianceToken = await tokenByCompliance();
            const operatorToken = await tokenByOperator();
            const user = (await hre.ethers.getSigners())[5];
            await operatorToken.updateOperator(user.address);
            expect(await complianceToken.operator()).to.equal(user.address);
        });
    });


    describe("Pausable",function(){

        it("Should pause the contract",async function () {
            const complianceToken = await tokenByCompliance();

            expect(await complianceToken.paused()).to.equal(false);

            await complianceToken.pause();
            expect(await complianceToken.paused()).to.equal(true);

            await complianceToken.unpause();
            expect(await complianceToken.paused()).to.equal(false);
            
        });

        it("Should fail if the contract paused",async function () {
            const complianceToken = await tokenByCompliance();
            await complianceToken.pause();
           
            expect(await complianceToken.paused()).to.equal(true);
            
            const user = (await hre.ethers.getSigners())[6];

            await expect(complianceToken.whitelist(user.address)).to.be.revertedWith("Pausable: paused");
            await expect(complianceToken.freeze(user.address)).to.be.revertedWith("Pausable: paused");
            await expect(complianceToken.approve(user.address,1000n)).to.be.revertedWith("Pausable: paused");
            await expect(complianceToken.totalSupply()).to.be.not.revertedWith("Pausable: paused");
            
            
            await complianceToken.unpause();
            expect(await complianceToken.paused()).to.equal(false);
            expect(await complianceToken.totalSupply()).to.equal(0n);

        });

    });


    describe("Rescuable",function(){
        it("Should rescuable token",async function () {
            const { token, compliance,operator } = await loadFixture(deployStableCoinProxy);
        
            await compliance.sendTransaction({
                to:await token.getAddress(),
                value:100n
            });
            
            expect(await hre.ethers.provider.getBalance(await token.getAddress())).to.equal(100n);

            const complianceToken = await hre.ethers.getContractAt("StablecoinToken",await token.getAddress(),compliance);

            const user = (await hre.ethers.getSigners())[6];
            
            await expect(complianceToken.rescueNativeCurrency(user.address,50n)).to.emit(complianceToken,"RescueNativeCurrency").withArgs(user.address,50n);

            expect(await hre.ethers.provider.getBalance(await token.getAddress())).to.equal(50n);
        });

        it("Should rescuable token fail",async function () {
            const { token, compliance,operator } = await loadFixture(deployStableCoinProxy);
        
            await compliance.sendTransaction({
                to:await token.getAddress(),
                value:100n
            });
            
            expect(await hre.ethers.provider.getBalance(await token.getAddress())).to.equal(100n);

            const complianceToken = await hre.ethers.getContractAt("StablecoinToken",await token.getAddress(),compliance);

            const user = (await hre.ethers.getSigners())[6];
            
            await expect(complianceToken.rescueNativeCurrency(user.address,150n)).to.be.reverted;
        });
    });


});

