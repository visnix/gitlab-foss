import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createNoteMutation from 'ee/security_dashboard/graphql/mutations/note_create.mutation.graphql';
import destroyNoteMutation from 'ee/security_dashboard/graphql/mutations/note_destroy.mutation.graphql';
import updateNoteMutation from 'ee/security_dashboard/graphql/mutations/note_update.mutation.graphql';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import HistoryComment from 'ee/vulnerabilities/components/history_comment.vue';
import HistoryCommentEditor from 'ee/vulnerabilities/components/history_comment_editor.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { TYPE_DISCUSSION, TYPE_VULNERABILITY } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';

jest.mock('~/flash');
Vue.use(VueApollo);

const CREATE_NOTE = 'createNote';
const UPDATE_NOTE = 'updateNote';
const DESTROY_NOTE = 'destroyNote';

const TEST_VULNERABILITY_ID = '15';
const TEST_DISCUSSION_ID = '24';
const TEST_VULNERABILITY_GID = convertToGraphQLId(TYPE_VULNERABILITY, TEST_VULNERABILITY_ID);
const TEST_DISCUSSION_GID = convertToGraphQLId(TYPE_DISCUSSION, TEST_DISCUSSION_ID);

describe('History Comment', () => {
  let wrapper;
  let createNoteMutationSpy;
  let updateNoteMutationSpy;
  let destroyNoteMutationSpy;

  const createMutationResponse = ({ note = {}, queryName, errors = [] }) => ({
    data: {
      [queryName]: {
        errors,
        note,
      },
    },
  });

  const createWrapper = ({ propsData } = {}) => {
    const apolloProvider = createMockApollo([
      [createNoteMutation, createNoteMutationSpy],
      [updateNoteMutation, updateNoteMutationSpy],
      [destroyNoteMutation, destroyNoteMutationSpy],
    ]);

    wrapper = mount(HistoryComment, {
      apolloProvider,
      provide: {
        vulnerabilityId: TEST_VULNERABILITY_ID,
      },
      propsData: {
        discussionId: TEST_DISCUSSION_ID,
        ...propsData,
      },
    });
  };

  const note = {
    id: 'gid://gitlab/DiscussionNote/1295',
    body: 'Created a note.',
    bodyHtml: '\u003cp\u003eCreated a note\u003c/p\u003e',
    updatedAt: '2021-08-25T16:21:18Z',
    system: false,
    systemNoteIconName: null,
    userPermissions: {
      adminNote: true,
    },
    author: {
      id: 'gid://gitlab/User/1',
      name: 'Administrator',
      username: 'root',
      webPath: '/root',
    },
  };

  // Needed for now. Will be removed when fetching notes will be done through GraphQL.
  note.note = note.body;
  note.noteHtml = note.bodyHtml;
  note.currentUser = { canEdit: note.userPermissions.adminNote };

  beforeEach(() => {
    createNoteMutationSpy = jest
      .fn()
      .mockResolvedValue(createMutationResponse({ queryName: CREATE_NOTE, note }));
    destroyNoteMutationSpy = jest
      .fn()
      .mockResolvedValue(createMutationResponse({ queryName: DESTROY_NOTE, note: null }));
    updateNoteMutationSpy = jest
      .fn()
      .mockResolvedValue(createMutationResponse({ queryName: UPDATE_NOTE, note }));
  });

  const addCommentButton = () => wrapper.find({ ref: 'addCommentButton' });
  const commentEditor = () => wrapper.find(HistoryCommentEditor);
  const eventItem = () => wrapper.find(EventItem);
  const editButton = () => wrapper.find('[title="Edit Comment"]');
  const deleteButton = () => wrapper.find('[title="Delete Comment"]');
  const confirmDeleteButton = () => wrapper.find({ ref: 'confirmDeleteButton' });
  const cancelDeleteButton = () => wrapper.find({ ref: 'cancelDeleteButton' });

  // Check that the passed-in elements exist, and that everything else does not exist.
  const expectExists = (...expectedElements) => {
    const set = new Set(expectedElements);

    expect(addCommentButton().exists()).toBe(set.has(addCommentButton));
    expect(commentEditor().exists()).toBe(set.has(commentEditor));
    expect(eventItem().exists()).toBe(set.has(eventItem));
    expect(editButton().exists()).toBe(set.has(editButton));
    expect(deleteButton().exists()).toBe(set.has(deleteButton));
    expect(confirmDeleteButton().exists()).toBe(set.has(confirmDeleteButton));
    expect(cancelDeleteButton().exists()).toBe(set.has(cancelDeleteButton));
  };

  const expectAddCommentView = () => expectExists(addCommentButton);
  const expectExistingCommentView = () => expectExists(eventItem, editButton, deleteButton);
  const expectEditCommentView = () => expectExists(commentEditor);
  const expectDeleteConfirmView = () => {
    expectExists(eventItem, confirmDeleteButton, cancelDeleteButton);
  };

  // Either the add comment button or the edit button will exist, but not both at the same time, so we'll just find
  // whichever one exists and click it to show the editor.
  const showEditView = () => {
    if (addCommentButton().exists()) {
      addCommentButton().trigger('click');
    } else {
      editButton().vm.$emit('click');
    }

    return wrapper.vm.$nextTick();
  };

  const editAndSaveNewContent = async (content) => {
    await showEditView();
    commentEditor().vm.$emit('onSave', content);
  };

  afterEach(() => {
    wrapper.destroy();
    createFlash.mockReset();
  });

  describe(`when there's no existing comment`, () => {
    beforeEach(() => createWrapper());

    it('shows the add comment button', () => {
      expectAddCommentView();
    });

    it('shows the comment editor when the add comment button is clicked', () => {
      return showEditView().then(() => {
        expectEditCommentView();
        expect(commentEditor().props('initialComment')).toBeFalsy();
      });
    });

    it('shows the add comment button when the cancel button is clicked in the comment editor', () => {
      return showEditView()
        .then(() => {
          commentEditor().vm.$emit('onCancel');
          return wrapper.vm.$nextTick();
        })
        .then(expectAddCommentView);
    });
  });

  describe(`when there's an existing comment`, () => {
    beforeEach(() => createWrapper({ propsData: { comment: note, discussionId: '24' } }));

    it('shows the comment with the correct user author and timestamp and the edit/delete buttons', () => {
      expectExistingCommentView();
      expect(eventItem().props('author')).toBe(note.author);
      expect(eventItem().props('createdAt')).toBe(note.updatedAt);
      expect(eventItem().element.innerHTML).toContain(note.bodyHtml);
    });

    it('shows the comment editor when the edit button is clicked', () => {
      return showEditView().then(() => {
        expectEditCommentView();
        expect(commentEditor().props('initialComment')).toBe(note.body);
      });
    });

    it('shows the comment when the cancel button is clicked in the comment editor', () => {
      return showEditView()
        .then(() => {
          commentEditor().vm.$emit('onCancel');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expectExistingCommentView();
          expect(eventItem().element.innerHTML).toContain(note.bodyHtml);
        });
    });

    it('shows the delete confirmation buttons when the delete button is clicked', () => {
      deleteButton().trigger('click');

      return wrapper.vm.$nextTick().then(expectDeleteConfirmView);
    });

    it('shows the comment when the cancel button is clicked on the delete confirmation', () => {
      deleteButton().trigger('click');

      return wrapper.vm
        .$nextTick()
        .then(() => {
          cancelDeleteButton().trigger('click');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expectExistingCommentView();
          expect(eventItem().element.innerHTML).toContain(note.bodyHtml);
        });
    });
  });

  const EXPECTED_CREATE_VARS = {
    discussionId: TEST_DISCUSSION_GID,
    noteableId: TEST_VULNERABILITY_GID,
  };
  const EXPECTED_UPDATE_VARS = {
    id: note.id,
  };

  describe.each`
    desc                           | propsData            | expectedEvent         | expectedVars            | mutationSpyFn                  | queryName
    ${'inserting a new note'}      | ${{}}                | ${'onCommentAdded'}   | ${EXPECTED_CREATE_VARS} | ${() => createNoteMutationSpy} | ${CREATE_NOTE}
    ${'updating an existing note'} | ${{ comment: note }} | ${'onCommentUpdated'} | ${EXPECTED_UPDATE_VARS} | ${() => updateNoteMutationSpy} | ${UPDATE_NOTE}
  `('$desc', ({ propsData, expectedEvent, expectedVars, mutationSpyFn, queryName }) => {
    let mutationSpy;

    beforeEach(() => {
      mutationSpy = mutationSpyFn();
    });

    it('sends graphql mutation', async () => {
      createWrapper({ propsData });

      await editAndSaveNewContent('new comment');

      expect(mutationSpy).toHaveBeenCalledWith({
        ...expectedVars,
        body: 'new comment',
      });
    });

    it('shows loading', async () => {
      createWrapper({ propsData });

      await editAndSaveNewContent('new comment');
      await wrapper.vm.$nextTick();

      expect(commentEditor().props('isSaving')).toBe(true);
    });

    it('emits event when mutation is successful', async () => {
      createWrapper({ propsData });

      await editAndSaveNewContent('new comment');
      await waitForPromises();

      expect(wrapper.emitted(expectedEvent)).toEqual([
        [
          {
            ...note,
            id: 1295,
            author: {
              ...note.author,
              id: 1,
              path: note.author.webPath,
            },
          },
        ],
      ]);
    });

    describe('when mutation has data error', () => {
      beforeEach(() => {
        mutationSpy.mockResolvedValue({ queryName, errors: ['Some domain specific error'] });
        createWrapper({ propsData });
      });

      it('shows flash', async () => {
        await editAndSaveNewContent('new comment');
        await waitForPromises();

        expect(createFlash).toHaveBeenCalledWith({
          message: 'Something went wrong while trying to save the comment. Please try again later.',
        });
      });
    });

    describe('when mutation has top-level error', () => {
      beforeEach(() => {
        mutationSpy.mockRejectedValue(new Error('Something top-level happened'));

        createWrapper({ propsData });
      });

      it('shows flash', async () => {
        await editAndSaveNewContent('new comment');
        await waitForPromises();

        expect(createFlash).toHaveBeenCalledWith({
          message: 'Something went wrong while trying to save the comment. Please try again later.',
        });

        expect(commentEditor().exists()).toBe(true);
      });
    });
  });

  describe('deleting a note', () => {
    it('deletes the comment when the confirm delete button is clicked', async () => {
      createWrapper({
        propsData: { comment: note },
      });

      deleteButton().trigger('click');

      await wrapper.vm.$nextTick();
      confirmDeleteButton().trigger('click');

      await wrapper.vm.$nextTick();
      expect(confirmDeleteButton().props('loading')).toBe(true);
      expect(cancelDeleteButton().props('disabled')).toBe(true);

      await waitForPromises();
      expect(wrapper.emitted().onCommentDeleted).toBeTruthy();
      expect(wrapper.emitted().onCommentDeleted[0][0]).toEqual(note);
    });

    it('sends mutation to delete note', async () => {
      createWrapper({ propsData: { comment: note } });

      deleteButton().trigger('click');
      await wrapper.vm.$nextTick();

      confirmDeleteButton().trigger('click');
      expect(destroyNoteMutationSpy).toHaveBeenCalledWith({
        id: note.id,
      });
    });

    it('with data error, shows an error message', async () => {
      destroyNoteMutationSpy.mockResolvedValue({ errors: ['Some domain specific error'] });
      createWrapper({ propsData: { comment: note } });

      deleteButton().trigger('click');

      await wrapper.vm.$nextTick();
      confirmDeleteButton().trigger('click');

      await waitForPromises();

      expect(createFlash).toHaveBeenCalledWith({
        message: 'Something went wrong while trying to delete the comment. Please try again later.',
      });
    });

    it('with top-level error, shows an error message', async () => {
      destroyNoteMutationSpy.mockRejectedValue(new Error('Some top-level error'));
      createWrapper({ propsData: { comment: note } });

      deleteButton().trigger('click');

      await wrapper.vm.$nextTick();
      confirmDeleteButton().trigger('click');

      await waitForPromises();
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Something went wrong while trying to delete the comment. Please try again later.',
      });
    });
  });

  describe('no permission to edit existing comment', () => {
    it('does not show the edit/delete buttons if the current user has no edit permissions', () => {
      createWrapper({
        propsData: {
          comment: { ...note, userPermissions: undefined, currentUser: { canEdit: false } },
        },
      });

      expect(editButton().exists()).toBe(false);
      expect(deleteButton().exists()).toBe(false);
    });
  });
});
