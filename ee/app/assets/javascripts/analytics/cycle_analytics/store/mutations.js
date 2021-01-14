import { toArray } from 'lodash';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { transformRawStages } from '../utils';
import * as types from './mutation_types';

export default {
  [types.SET_FEATURE_FLAGS](state, featureFlags) {
    state.featureFlags = featureFlags;
  },
  [types.SET_SELECTED_PROJECTS](state, projects) {
    state.selectedProjects = projects;
  },
  [types.SET_SELECTED_STAGE](state, rawData) {
    state.selectedStage = convertObjectPropsToCamelCase(rawData);
  },
  [types.SET_DATE_RANGE](state, { startDate, endDate }) {
    state.startDate = startDate;
    state.endDate = endDate;
  },
  [types.REQUEST_CYCLE_ANALYTICS_DATA](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](state) {
    state.errorCode = null;
    state.isLoading = false;
  },
  [types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR](state, errCode) {
    state.errorCode = errCode;
    state.isLoading = false;
  },
  [types.REQUEST_STAGE_DATA](state) {
    state.isLoadingStage = true;
    state.isEmptyStage = false;
    state.selectedStageError = '';
  },
  [types.RECEIVE_STAGE_DATA_SUCCESS](state, events = []) {
    state.currentStageEvents = events.map((fields) =>
      convertObjectPropsToCamelCase(fields, { deep: true }),
    );
    state.isEmptyStage = !events.length;
    state.isLoadingStage = false;
    state.selectedStageError = '';
  },
  [types.RECEIVE_STAGE_DATA_ERROR](state, message) {
    state.isEmptyStage = true;
    state.isLoadingStage = false;
    state.selectedStageError = message;
  },
  [types.REQUEST_STAGE_MEDIANS](state) {
    state.medians = {};
  },
  [types.RECEIVE_STAGE_MEDIANS_SUCCESS](state, medians = []) {
    state.medians = medians.reduce(
      (acc, { id, value, error = null }) => ({
        ...acc,
        [id]: { value, error },
      }),
      {},
    );
  },
  [types.RECEIVE_STAGE_MEDIANS_ERROR](state) {
    state.medians = {};
  },
  [types.REQUEST_GROUP_STAGES](state) {
    state.stages = [];
  },
  [types.RECEIVE_GROUP_STAGES_ERROR](state) {
    state.stages = [];
  },
  [types.RECEIVE_GROUP_STAGES_SUCCESS](state, stages) {
    const transformedStages = transformRawStages(stages);
    state.stages = transformedStages.sort((a, b) => a?.id > b?.id);
  },
  [types.REQUEST_UPDATE_STAGE](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_UPDATE_STAGE_SUCCESS](state) {
    state.isLoading = false;
  },
  [types.RECEIVE_UPDATE_STAGE_ERROR](state) {
    state.isLoading = false;
  },
  [types.REQUEST_REMOVE_STAGE](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_REMOVE_STAGE_RESPONSE](state) {
    state.isLoading = false;
  },
  [types.INITIALIZE_CYCLE_ANALYTICS](
    state,
    {
      group = null,
      createdAfter: startDate = null,
      createdBefore: endDate = null,
      selectedProjects = [],
      selectedValueStream = {},
    } = {},
  ) {
    state.isLoading = true;
    state.currentGroup = group;
    state.selectedProjects = selectedProjects;
    state.selectedValueStream = selectedValueStream;
    state.startDate = startDate;
    state.endDate = endDate;
  },
  [types.INITIALIZE_CYCLE_ANALYTICS_SUCCESS](state) {
    state.isLoading = false;
  },
  [types.REQUEST_REORDER_STAGE](state) {
    state.isSavingStageOrder = true;
    state.errorSavingStageOrder = false;
  },
  [types.RECEIVE_REORDER_STAGE_SUCCESS](state) {
    state.isSavingStageOrder = false;
    state.errorSavingStageOrder = false;
  },
  [types.RECEIVE_REORDER_STAGE_ERROR](state) {
    state.isSavingStageOrder = false;
    state.errorSavingStageOrder = true;
  },
  [types.REQUEST_CREATE_VALUE_STREAM](state) {
    state.isCreatingValueStream = true;
    state.createValueStreamErrors = {};
  },
  [types.RECEIVE_CREATE_VALUE_STREAM_ERROR](state, { data: { stages }, errors = {} }) {
    state.isCreatingValueStream = false;

    // TODO: move to utils + add additional specs
    // TODO: should test that we end up with the same amount of errors as stages
    // This is because the JSON response only includes failed stages with an index of the stage
    const { stages: stageErrors = {}, ...rest } = errors;
    const fullStageErrors = Object.keys(stageErrors).length
      ? stages.map((_, index) => {
          return convertObjectPropsToCamelCase(stageErrors[index]) || {};
        })
      : {};

    // NOTE: BE currently returns the equivalent of a JS hash for the stages errors, an array simplifies things
    state.createValueStreamErrors = { ...rest, stages: fullStageErrors };
  },
  [types.RECEIVE_CREATE_VALUE_STREAM_SUCCESS](state, valueStream) {
    state.isCreatingValueStream = false;
    state.createValueStreamErrors = {};
    state.selectedValueStream = convertObjectPropsToCamelCase(valueStream);
  },
  [types.REQUEST_DELETE_VALUE_STREAM](state) {
    state.isDeletingValueStream = true;
    state.deleteValueStreamError = null;
  },
  [types.RECEIVE_DELETE_VALUE_STREAM_ERROR](state, message) {
    state.isDeletingValueStream = false;
    state.deleteValueStreamError = message;
  },
  [types.RECEIVE_DELETE_VALUE_STREAM_SUCCESS](state) {
    state.isDeletingValueStream = false;
    state.deleteValueStreamError = null;
    state.selectedValueStream = null;
  },
  [types.SET_SELECTED_VALUE_STREAM](state, valueStream) {
    state.selectedValueStream = convertObjectPropsToCamelCase(valueStream);
  },
  [types.REQUEST_VALUE_STREAMS](state) {
    state.isLoadingValueStreams = true;
    state.valueStreams = [];
  },
  [types.RECEIVE_VALUE_STREAMS_ERROR](state, errCode) {
    state.errCode = errCode;
    state.isLoadingValueStreams = false;
    state.valueStreams = [];
  },
  [types.RECEIVE_VALUE_STREAMS_SUCCESS](state, data) {
    state.isLoadingValueStreams = false;
    state.valueStreams = data
      .map(convertObjectPropsToCamelCase)
      .sort(({ name: aName = '' }, { name: bName = '' }) => {
        return aName.toUpperCase() > bName.toUpperCase() ? 1 : -1;
      });
  },
};
