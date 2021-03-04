import initTree from 'ee_else_ce/repository';
import Activities from '~/activities';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import BlobViewer from '~/blob/viewer/index';
import { initUploadForm } from '~/blob_edit/blob_bundle';
import leaveByUrl from '~/namespaces/leave_by_url';
import initVueNotificationsDropdown from '~/notifications';
import initReadMore from '~/read_more';
import UserCallout from '~/user_callout';
import Star from '../../../star';

initReadMore();
new Star(); // eslint-disable-line no-new

// eslint-disable-next-line no-new
new UserCallout({
  setCalloutPerProject: false,
  className: 'js-autodevops-banner',
});

// Project show page loads different overview content based on user preferences

if (document.querySelector('.js-upload-blob-form')) {
  initUploadForm();
}

if (document.getElementById('js-tree-list')) {
  initTree();
}

if (document.querySelector('.blob-viewer')) {
  new BlobViewer(); // eslint-disable-line no-new
}

if (document.querySelector('.project-show-activity')) {
  new Activities(); // eslint-disable-line no-new
}

leaveByUrl('project');

initVueNotificationsDropdown();

new ShortcutsNavigation(); // eslint-disable-line no-new
