import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";


describe("TransparentProxy", function () {

    const name = "StableCoinToken";
    const symbol = "SCT";
    const currency = "HSCT";
    const decimals = 18

    var tokenLogicAddress = "";
    var tokenProxyAddress = "";

    async function deployProxyAdminExtend() {
        const [adminAccount] = await hre.ethers.getSigners();
        const proxyAdminFactory = await hre.ethers.getContractFactory("ProxyAdminExtend",adminAccount);
        const proxyAdmin = await proxyAdminFactory.deploy();
        return { proxyAdmin, adminAccount };
    }

    async function deployStableCoinTokenLogic() {
        const [porxyAdmin, compliance, operator] = await hre.ethers.getSigners();
        const sToken = await hre.ethers.getContractFactory("StablecoinToken");
        const tokenLogic = await sToken.deploy();
        const newTokenLogic = await sToken.deploy();
        //console.log("token logic address:", await tokenLogic.getAddress());
        //console.log("new token logic address:", await newTokenLogic.getAddress());
        tokenLogicAddress = await tokenLogic.getAddress();

        return { tokenLogic, newTokenLogic, sToken };
    }

    async function deployStableCoinProxy() {

        const [adminAccount, compliance, operator] = await hre.ethers.getSigners();

        const { tokenLogic } = await loadFixture(deployStableCoinTokenLogic);

        const { proxyAdmin } = await loadFixture(deployProxyAdminExtend);

        const complianceAcc = compliance.address;
        const operatorAcc = operator.address;
        const burnAcc = "0x0000000000000000000000000000000000000001";

        //token.initialize(name, symbol, currency, decimals, compliance.address, operator.address);
        const tProxy = await hre.ethers.getContractFactory("TransparentUpgradeableProxy");
        const input = tokenLogic.interface.encodeFunctionData("initialize", [name, symbol, currency, decimals, complianceAcc, operatorAcc, burnAcc, true]);
        //console.log("input",input);
        
        const proxy = await tProxy.deploy(tokenLogic.getAddress(),await proxyAdmin.getAddress(), input);
        tokenProxyAddress = await proxy.getAddress();
        const token = await hre.ethers.getContractAt("StablecoinToken", await proxy.getAddress(), compliance);

        return { token, proxyAdmin,adminAccount, compliance, operator };
    }


    describe("Deployment", function () {
        it("Should deploy token logic", async function () {
            const { tokenLogic } = await loadFixture(deployStableCoinTokenLogic);

            expect(await tokenLogic.name()).to.equal("");
        });

        it("Should deploy token proxy", async function () {
            const { token, compliance } = await loadFixture(deployStableCoinProxy);

            expect(await token.name()).to.equal("StableCoinToken");
            expect(await token.compliance()).to.equal(compliance.address);

        });

    });

    describe("Proxy Manage", function () {

        it("Should load proxy manage", async function () {
            const { token, proxyAdmin } = await loadFixture(deployStableCoinProxy);
            const proxyAdminAddress = await proxyAdmin.getAddress()
            const proxyAddress = await token.getAddress();

            expect(await proxyAdmin.getProxyAdmin(proxyAddress)).to.equal(proxyAdminAddress);
        });

        it("Should load logic address", async function () {
            const { token, proxyAdmin } = await loadFixture(deployStableCoinProxy);
            const proxyAddress = await token.getAddress();

            expect(await proxyAdmin.getProxyImplementation(proxyAddress)).to.equal(tokenLogicAddress);
        });


        // it("Should change proxy admin", async function () {
        //     const proxyAdmin2 = (await hre.ethers.getSigners())[3];

        //     const { proxyManage, proxyAdmin } = await loadFixture(transparentProxyManage);
        //     await proxyManage.changeAdmin(proxyAdmin2.address);

        //     await expect(proxyManage.admin()).to.be.reverted;

        //     const proxyManage2 = await hre.ethers.getContractAt("ITransparentUpgradeableProxy", await proxyManage.getAddress(), proxyAdmin2);
        //     expect(await proxyManage2.admin()).to.equal(proxyAdmin2.address);
        // });

        it("Should upgrade", async function () {

            const { newTokenLogic, sToken } = await loadFixture(deployStableCoinTokenLogic);
            const newAddress = await newTokenLogic.getAddress();

            const { token, proxyAdmin } = await loadFixture(deployStableCoinProxy);
            const proxyAddress = await token.getAddress();
            await proxyAdmin.upgrade(proxyAddress,newAddress);

            expect(await proxyAdmin.getProxyImplementation(proxyAddress)).to.equal(newAddress);
            expect(await token.name()).to.equal(name);
        });

        it("Should init logic",async function () {

            const [adminAccount, compliance, operator] = await hre.ethers.getSigners();

            const { tokenLogic } = await loadFixture(deployStableCoinTokenLogic);

            const complianceAcc = compliance.address;
            const operatorAcc = operator.address;
            const burnAcc = "0x0000000000000000000000000000000000000001";
    
            await expect( tokenLogic.initialize(name, symbol, currency, decimals, complianceAcc, operatorAcc, burnAcc, true))
            .to.be.revertedWith("Initializable: contract is already initialized");
        });
    });

});

