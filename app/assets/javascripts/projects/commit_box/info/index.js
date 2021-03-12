import { fetchCommitMergeRequests } from '~/commit_merge_requests';
import { initCommitPipelineMiniGraph } from './init_commit_pipeline_mini_graph';
import { initDetailsButton } from './init_details_button';
import { loadBranches } from './load_branches';

export const initCommitBoxInfo = (containerSelector = '.js-commit-box-info') => {
  const containerEl = document.querySelector(containerSelector);

  // Display commit related branches
  loadBranches(containerEl);

  // Related merge requests to this commit
  fetchCommitMergeRequests();

  // Display pipeline mini graph for this commit
  initCommitPipelineMiniGraph();

  initDetailsButton();
};
