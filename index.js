// Pass the repo name
const recipe = "minting-a-moment-in-topshot-set";

//Generate paths of each code file to render
const contractPath = `${recipe}/cadence/contract.cdc`;
const transactionPath = `${recipe}/cadence/transaction.cdc`;

//Generate paths of each explanation file to render
const smartContractExplanationPath = `${recipe}/explanations/contract.txt`;
const transactionExplanationPath = `${recipe}/explanations/transaction.txt`;

export const mintingAMomentInTopShotSet = {
  slug: recipe,
  title: "Minting a Moment in TopShot Set",
  createdAt: new Date(2022, 3, 1),
  author: "Flow Blockchain",
  playgroundLink:
    "https://play.onflow.org/15c1e86e-010c-4a7c-bcfd-98a1bddc36a7?type=tx&id=d24e3b31-7576-4e7e-b27e-2ed422406187&storage=none",
  excerpt:
    "You've added plays in your set, now it's time to mint them. This code will mint moments or plays in your TopShot sets.",
  smartContractCode: contractPath,
  smartContractExplanation: smartContractExplanationPath,
  transactionCode: transactionPath,
  transactionExplanation: transactionExplanationPath,
  filters: {
    difficulty: "intermediate",
  },
};
