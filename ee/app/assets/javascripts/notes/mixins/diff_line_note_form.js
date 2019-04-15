import { mapActions, mapGetters, mapState } from 'vuex';
import { TEXT_DIFF_POSITION_TYPE, IMAGE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import { getDraftReplyFormData, getDraftFormData } from 'ee/batch_comments/utils';
import createFlash from '~/flash';
import { s__ } from '~/locale';

export default {
  computed: {
    ...mapState({
      noteableData: state => state.notes.noteableData,
      notesData: state => state.notes.notesData,
      withBatchComments: state => state.batchComments && state.batchComments.withBatchComments,
    }),
    ...mapGetters('diffs', ['getDiffFileByHash']),
    ...mapGetters('batchComments', ['shouldRenderDraftRowInDiscussion', 'draftForDiscussion']),
  },
  methods: {
    ...mapActions('diffs', ['cancelCommentForm']),
    ...mapActions('batchComments', ['addDraftToReview', 'saveDraft', 'insertDraftIntoDrafts']),
    addReplyToReview(noteText, isResolving) {
      const postData = getDraftReplyFormData({
        in_reply_to_discussion_id: this.discussion.reply_id,
        target_type: this.getNoteableData.targetType,
        notesData: this.notesData,
        draft_note: {
          note: noteText,
          resolve_discussion: isResolving,
        },
      });

      if (this.discussion.for_commit) {
        postData.note_project_id = this.discussion.project_id;
      }

      this.isReplying = false;

      this.saveDraft(postData)
        .then(() => {
          this.handleClearForm(this.discussion.line_code);
        })
        .catch(() => {
          createFlash(s__('MergeRequests|An error occurred while saving the draft comment.'));
        });
    },
    addToReview(note) {
      const positionType = this.diffFileCommentForm
        ? IMAGE_DIFF_POSITION_TYPE
        : TEXT_DIFF_POSITION_TYPE;
      const selectedDiffFile = this.getDiffFileByHash(this.diffFileHash);
      const postData = getDraftFormData({
        note,
        notesData: this.notesData,
        noteableData: this.noteableData,
        noteableType: this.noteableType,
        noteTargetLine: this.noteTargetLine,
        diffViewType: this.diffViewType,
        diffFile: selectedDiffFile,
        linePosition: this.position,
        positionType,
        ...this.diffFileCommentForm,
      });

      return this.saveDraft(postData)
        .then(() => {
          if (positionType === IMAGE_DIFF_POSITION_TYPE) {
            this.closeDiffFileCommentForm(this.diffFileHash);
          } else {
            this.handleClearForm(this.line.line_code);
          }
        })
        .catch(() => {
          createFlash(s__('MergeRequests|An error occurred while saving the draft comment.'));
        });
    },
    handleClearForm(lineCode) {
      this.cancelCommentForm({
        lineCode,
        fileHash: this.diffFileHash,
      });
      this.$nextTick(() => {
        this.resetAutoSave();
      });
    },
    showDraft(replyId) {
      if (this.withBatchComments) {
        return this.shouldRenderDraftRowInDiscussion(replyId);
      }

      return false;
    },
  },
};
