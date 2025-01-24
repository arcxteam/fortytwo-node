const ethers = require("ethers");
const fs = require("fs").promises;
const axios = require("axios");
const readline = require("readline");
const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const chalk = require("chalk");

const API_BASE = "https://dashboard.layeredge.io/api";

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

const question = (query) =>
  new Promise((resolve) => rl.question(query, resolve));

const headers = {
  accept: "*/*",
  "accept-language": "en-US,en;q=0.9",
  "content-type": "application/json",
  priority: "u=1, i",
  "sec-ch-ua":
    '"Not A(Brand";v="8", "Chromium";v="132", "Google Chrome";v="132"',
  "sec-ch-ua-mobile": "?0",
  "sec-ch-ua-platform": '"macOS"',
  "sec-fetch-dest": "empty",
  "sec-fetch-mode": "cors",
  "sec-fetch-site": "same-origin",
  referrer: "https://dashboard.layeredge.io/",
};

async function loadProxies() {
  try {
    const content = await fs.readFile("proxies.txt", "utf8");
    return content.split("\n").filter((line) => line.trim());
  } catch (error) {
    console.log(
      chalk.yellow("➜ No proxies.txt found, continuing without proxies")
    );
    return [];
  }
}

function getNextProxy(proxies, currentIndex) {
  if (!proxies.length) return null;
  return proxies[currentIndex % proxies.length];
}

function createAxiosConfig(headers, proxy = null) {
  const config = { headers };
  if (proxy) {
    config.proxy = false;
    config.httpsAgent = new (require("https-proxy-agent"))(proxy);
    config.httpAgent = new (require("http-proxy-agent"))(proxy);
  }
  return config;
}

async function generateWallet() {
  const wallet = ethers.Wallet.createRandom();
  return {
    address: wallet.address,
    privateKey: wallet.privateKey,
  };
}

async function retryOperation(operation, maxAttempts = 3) {
  let lastError;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const result = await operation();
      return result;
    } catch (error) {
      lastError = error;
      if (attempt < maxAttempts) {
        console.log(chalk.yellow(`  Attempt ${attempt} failed, retrying...`));
        await delay(2000 * attempt);
      }
    }
  }
  throw lastError;
}

async function validateInvite(referralCode, proxy = null) {
  try {
    const response = await retryOperation(async () => {
      return await axios.post(
        `${API_BASE}/validate-invite`,
        { code: referralCode },
        createAxiosConfig(headers, proxy)
      );
    });
    return response.data.success;
  } catch (error) {
    console.error("Error validating invite:", error.message);
    return false;
  }
}

async function registerWallet(walletAddress, referralCode, proxy = null) {
  try {
    const response = await retryOperation(async () => {
      return await axios.post(
        `${API_BASE}/proxy/register-wallet/${referralCode}`,
        { walletAddress },
        createAxiosConfig(headers, proxy)
      );
    });
    return response.data.data;
  } catch (error) {
    console.error("Error registering wallet:", error.message);
    return null;
  }
}

async function claimPoints(walletAddress, proxy = null) {
  try {
    const response = await retryOperation(async () => {
      return await axios.post(
        `${API_BASE}/claim-points`,
        { walletAddress },
        createAxiosConfig(headers, proxy)
      );
    });
    return response.data;
  } catch (error) {
    console.error("Error claiming points:", error.message);
    return null;
  }
}

async function saveWallet(walletData) {
  try {
    let wallets = [];
    try {
      const existing = await fs.readFile("wallets.json", "utf8");
      wallets = JSON.parse(existing);
    } catch (error) {}

    wallets.push(walletData);
    await fs.writeFile("wallets.json", JSON.stringify(wallets, null, 2));
  } catch (error) {
    console.error("Error saving wallet:", error.message);
  }
}

async function processWallet(referralCode, proxy = null) {
  const wallet = await generateWallet();
  console.log(
    chalk.cyan(
      `\n➜ New Wallet: ${wallet.address.slice(0, 6)}...${wallet.address.slice(
        -4
      )}`
    )
  );
  if (proxy) {
    console.log(
      chalk.gray(`  Using proxy: ${proxy.slice(0, 10)}...${proxy.slice(-10)}`)
    );
  }

  const isValid = await validateInvite(referralCode, proxy);
  if (!isValid) {
    console.log(chalk.red("✖ Invalid referral code"));
    return false;
  }

  const registration = await registerWallet(
    wallet.address,
    referralCode,
    proxy
  );
  if (!registration) {
    console.log(chalk.red("✖ Failed to register wallet"));
    return false;
  }

  const claimed = await claimPoints(wallet.address, proxy);
  if (!claimed) {
    console.log(chalk.red("✖ Failed to claim points"));
    return false;
  }

  const walletData = {
    ...wallet,
    referralCode: registration.referralCode,
    totalPoints: claimed.totalPoints,
    timestamp: new Date().toISOString(),
    usedProxy: proxy,
  };

  await saveWallet(walletData);
  console.log(chalk.green(`✔ Success: ${claimed.totalPoints} points claimed`));
  return true;
}

async function main() {
  try {
    console.clear();
    console.log(
      chalk.bold.cyan("\n=== LayerEdge Referral Bot by @jinwooid ===\n")
    );

    const proxies = await loadProxies();
    if (proxies.length > 0) {
      console.log(chalk.green(`➜ Loaded ${proxies.length} proxies`));
    }

    const referralCode = await question(
      chalk.yellow("Enter your referral code: ")
    );

    const numberOfWalletsInput = await question(
      chalk.yellow("Enter number of wallets to generate: ")
    );
    const numberOfWallets = parseInt(numberOfWalletsInput);

    if (isNaN(numberOfWallets) || numberOfWallets <= 0) {
      console.log(chalk.red("\n✖ Please enter a valid number greater than 0"));
      return;
    }

    console.log(chalk.cyan("\n➜ Starting process"));
    console.log(chalk.gray(`  Referral code: ${referralCode}`));
    console.log(chalk.gray(`  Target wallets: ${numberOfWallets}`));

    let successful = 0;
    for (let i = 0; i < numberOfWallets; i++) {
      console.log(chalk.cyan(`\n➜ Progress: ${i + 1}/${numberOfWallets}`));
      const proxy = getNextProxy(proxies, i);
      const result = await processWallet(referralCode, proxy);
      if (result) successful++;
      await delay(5000);
    }

    console.log(chalk.bold.green(`\n✔ Process completed!`));
    console.log(
      chalk.gray(
        `  Successfully processed: ${successful}/${numberOfWallets} wallets`
      )
    );
    console.log(chalk.gray("  Details saved in wallets.json"));
  } catch (error) {
    console.error(chalk.red("\n✖ Error:"), error.message);
  } finally {
    rl.close();
  }
}

main().catch(console.error);
