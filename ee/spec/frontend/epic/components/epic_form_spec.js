import { GlForm } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { ApolloMutation } from 'vue-apollo';
import EpicForm from 'ee/epic/components/epic_form.vue';
import createEpic from 'ee/epic/queries/createEpic.mutation.graphql';
import { TEST_HOST } from 'helpers/test_constants';
import { visitUrl } from '~/lib/utils/url_utility';
import LabelsSelectVue from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
}));

const TEST_GROUP_PATH = 'gitlab-org';
const TEST_NEW_EPIC = { data: { createEpic: { epic: { webUrl: TEST_HOST } } } };
const TEST_FAILED = { data: { createEpic: { errors: ['mutation failed'] } } };

describe('ee/epic/components/epic_form.vue', () => {
  let wrapper;

  const createWrapper = ({ mutationResult = TEST_NEW_EPIC } = {}) => {
    wrapper = shallowMount(EpicForm, {
      provide: {
        iid: '1',
        groupPath: TEST_GROUP_PATH,
        groupEpicsPath: TEST_HOST,
        labelsFetchPath: TEST_HOST,
        labelsManagePath: TEST_HOST,
        markdownPreviewPath: TEST_HOST,
        markdownDocsPath: TEST_HOST,
      },
      stubs: {
        ApolloMutation,
        MarkdownField: { template: '<div><slot name="textarea"></slot></div>' },
      },
      mocks: {
        $apollo: {
          mutate: jest.fn().mockResolvedValue(mutationResult),
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findForm = () => wrapper.find(GlForm);
  const findLabels = () => wrapper.find(LabelsSelectVue);
  const findTitle = () => wrapper.find('[data-testid="epic-title"]');
  const findDescription = () => wrapper.find('[data-testid="epic-description"]');
  const findConfidentialityCheck = () => wrapper.find('[data-testid="epic-confidentiality"]');
  const findStartDate = () => wrapper.find('[data-testid="epic-start-date"]');
  const findStartDateReset = () => wrapper.find('[data-testid="clear-start-date"]');
  const findDueDate = () => wrapper.find('[data-testid="epic-due-date"]');
  const findDueDateReset = () => wrapper.find('[data-testid="clear-due-date"]');
  const findSaveButton = () => wrapper.find('[data-testid="save-epic"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel-epic"]');

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the form', () => {
      expect(findForm().exists()).toBe(true);
    });

    it('can be canceled', () => {
      expect(findCancelButton().attributes('href')).toBe(TEST_HOST);
    });

    it('disables submit button if no title is provided', () => {
      expect(findSaveButton().attributes('disabled')).toBeTruthy();
    });

    it.each`
      field               | findInput        | findResetter
      ${'startDateFixed'} | ${findStartDate} | ${findStartDateReset}
      ${'dueDateFixed'}   | ${findDueDate}   | ${findDueDateReset}
    `('can clear $field with side control', ({ field, findInput, findResetter }) => {
      findInput().vm.$emit('input', new Date());

      expect(wrapper.vm[field]).toBeTruthy();

      findResetter().vm.$emit('click');

      return nextTick().then(() => {
        expect(wrapper.vm[field]).toBe(null);
      });
    });
  });

  describe('save', () => {
    const addLabelIds = [1];
    const title = 'Status page MVP';
    const description = '### Goal\n\n- [ ] Item';
    const confidential = true;

    it.each`
      startDateFixed  | dueDateFixed    | startDateIsFixed | dueDateIsFixed
      ${null}         | ${null}         | ${false}         | ${false}
      ${'2021-07-01'} | ${null}         | ${true}          | ${false}
      ${null}         | ${'2021-07-02'} | ${false}         | ${true}
      ${'2021-07-01'} | ${'2021-07-02'} | ${true}          | ${true}
    `(
      'requests mutation with correct data with all start and due date configurations',
      async ({ startDateFixed, dueDateFixed, startDateIsFixed, dueDateIsFixed }) => {
        createWrapper();

        findTitle().vm.$emit('input', title);
        findDescription().setValue(description);
        findConfidentialityCheck().vm.$emit('input', confidential);
        findLabels().vm.$emit('updateSelectedLabels', [{ id: 1, set: 1 }]);

        // Make sure the submitted values for start and due dates are date strings without timezone info.
        // (Datepicker emits a Date object but the submitted value must be a date string).
        findStartDate().vm.$emit('input', startDateFixed ? new Date(startDateFixed) : null);
        findDueDate().vm.$emit('input', dueDateFixed ? new Date(dueDateFixed) : null);

        findForm().vm.$emit('submit', { preventDefault: () => {} });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: createEpic,
          variables: {
            input: {
              groupPath: TEST_GROUP_PATH,
              addLabelIds,
              title,
              description,
              confidential,
              startDateFixed,
              startDateIsFixed,
              dueDateFixed,
              dueDateIsFixed,
            },
          },
        });

        await nextTick();

        expect(visitUrl).toHaveBeenCalled();
      },
    );

    it.each`
      status        | result           | loading
      ${'succeeds'} | ${TEST_NEW_EPIC} | ${true}
      ${'fails'}    | ${TEST_FAILED}   | ${false}
    `('resets loading indicator when $status', ({ result, loading }) => {
      createWrapper({ mutationResult: result });

      const savePromise = wrapper.vm.save();

      expect(wrapper.vm.loading).toBe(true);

      return savePromise.then(() => {
        expect(findSaveButton().props('loading')).toBe(loading);
      });
    });
  });
});
