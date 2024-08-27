# ida-contracts

## build

```
npm install

npm install --save-dev hardhat

npx hardhat compile
```

## test

```
npx hardhat test
```

## deploy

1. deploy ProxyAdmin.  
2. deploy logic contract.  
3. deploy proxy contract.  

```
cp .env.example .env
```
Modify test network parameters and signer private key in `.env` .  


```
npx hardhat ignition deploy ignition/modules/TransparentProxy.ts --parameters ignition/modules/TransparentProxy.json --network localhost

```
**parameters** : Deployment parameters of the contract  
**deployment-id** : Deployment id  
**network** : Deployed network identity，[localhost:local hardhat test node ;testnet: local nodes configured in `.env`]  

If using a localhost network, the hradhat node must be started.
```
npx hardhat node 
```