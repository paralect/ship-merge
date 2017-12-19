const logger = require('./logger');
const git = require('nodegit');
const gitTag = git.Tag;
const repos = require('./repos');
const path = require('path');
const fse = require('fs-extra');
var gitCheckout = git.Checkout;
const WORK_DIR = './tmp';

const emptyWorkDir = async (workDir) => {
  try {
    await fse.emptyDir(workDir);
  } catch (e) {
    logger.info(`Coundn't clean up work dir: ${workDir}`);
  }
};

const checkoutAtTag = async ({repoOptions, workDir}) => {
  const repoDestination = path.join(workDir, repoOptions.name);
  const repo = await git.Clone(repoOptions.url, repoDestination);
  const tagReference = await repo.getBranch(repoOptions.version);
  await repo.checkoutRef(tagReference);
  const commit = await repo.getHeadCommit();
  
  return {
    id: commit.id().tostrS(),
    message: commit.message().replace(/\r?\n?/g, ''),
  }
}

const combineRepos = async () => {
  const commitInfo = await checkoutAtTag({ repoOptions: repos.Landing, workDir: WORK_DIR });
  logger.info(`Checked out repo [${repos.Landing.name}] at commit: [${commitInfo.id}]`);
  logger.info(`Commit message: ${commitInfo.message}`);
}

try {
  emptyWorkDir(WORK_DIR);
  combineRepos();
} catch(err) {
  logger.error(err);
}
