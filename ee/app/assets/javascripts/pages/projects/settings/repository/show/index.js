/* eslint-disable no-new */
import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';
import initSettingsPanels from '~/settings_panels';
import initDeployKeys from '~/deploy_keys';
import ProtectedTagCreateEE from 'ee/protected_tags/protected_tag_create';
import ProtectedTagEditListEE from 'ee/protected_tags/protected_tag_edit_list';
import ProtectedTagCreateCE from '~/protected_tags/protected_tag_create';
import ProtectedTagEditListCE from '~/protected_tags/protected_tag_edit_list';

document.addEventListener('DOMContentLoaded', () => {
  new UsersSelect();
  new UserCallout();
  if (document.querySelector('.js-protected-refs-for-users')) {
    new ProtectedTagCreateEE();
    new ProtectedTagEditListEE();
  } else {
    new ProtectedTagCreateCE();
    new ProtectedTagEditListCE();
  }
  initDeployKeys();
  initSettingsPanels();
});
