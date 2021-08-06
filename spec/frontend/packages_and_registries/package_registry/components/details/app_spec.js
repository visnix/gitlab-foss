import { GlEmptyState } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';

import AdditionalMetadata from '~/packages_and_registries/package_registry/components/details/additional_metadata.vue';
import PackagesApp from '~/packages_and_registries/package_registry/components/details/app.vue';
import InstallationCommands from '~/packages_and_registries/package_registry/components/details/installation_commands.vue';
import PackageHistory from '~/packages_and_registries/package_registry/components/details/package_history.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/details/package_title.vue';
import { FETCH_PACKAGE_DETAILS_ERROR_MESSAGE } from '~/packages_and_registries/package_registry/constants';
import getPackageDetails from '~/packages_and_registries/package_registry/graphql/queries/get_package_details.query.graphql';
import { packageDetailsQuery, packageData, emptyPackageDetailsQuery } from '../../mock_data';

jest.mock('~/flash');

const localVue = createLocalVue();

describe('PackagesApp', () => {
  let wrapper;
  let apolloProvider;

  const provide = {
    packageId: '111',
    titleComponent: 'PackageTitle',
    projectName: 'projectName',
    canDelete: 'canDelete',
    svgPath: 'svgPath',
    npmPath: 'npmPath',
    npmHelpPath: 'npmHelpPath',
    projectListUrl: 'projectListUrl',
    groupListUrl: 'groupListUrl',
  };

  function createComponent({ resolver = jest.fn().mockResolvedValue(packageDetailsQuery()) } = {}) {
    localVue.use(VueApollo);

    const requestHandlers = [[getPackageDetails, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMount(PackagesApp, {
      localVue,
      apolloProvider,
      provide,
    });
  }

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPackageTitle = () => wrapper.findComponent(PackageTitle);
  const findPackageHistory = () => wrapper.findComponent(PackageHistory);
  const findAdditionalMetadata = () => wrapper.findComponent(AdditionalMetadata);
  const findInstallationCommands = () => wrapper.findComponent(InstallationCommands);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders an empty state component', async () => {
    createComponent({ resolver: jest.fn().mockResolvedValue(emptyPackageDetailsQuery) });

    await waitForPromises();

    expect(findEmptyState().exists()).toBe(true);
  });

  it('renders the app and displays the package title', async () => {
    createComponent();

    await waitForPromises();

    expect(findPackageTitle().exists()).toBe(true);
    expect(findPackageTitle().props()).toMatchObject({
      packageEntity: expect.objectContaining(packageData()),
    });
  });

  it('emits an error message if the load fails', async () => {
    createComponent({ resolver: jest.fn().mockRejectedValue() });

    await waitForPromises();

    expect(createFlash).toHaveBeenCalledWith(
      expect.objectContaining({
        message: FETCH_PACKAGE_DETAILS_ERROR_MESSAGE,
      }),
    );
  });

  it('renders history and has the right props', async () => {
    createComponent();

    await waitForPromises();

    expect(findPackageHistory().exists()).toBe(true);
    expect(findPackageHistory().props()).toMatchObject({
      packageEntity: expect.objectContaining(packageData()),
      projectName: provide.projectName,
    });
  });

  it('renders additional metadata and has the right props', async () => {
    createComponent();

    await waitForPromises();

    expect(findAdditionalMetadata().exists()).toBe(true);
    expect(findAdditionalMetadata().props()).toMatchObject({
      packageEntity: expect.objectContaining(packageData()),
    });
  });

  it('renders installation commands and has the right props', async () => {
    createComponent();

    await waitForPromises();

    expect(findInstallationCommands().exists()).toBe(true);
    expect(findInstallationCommands().props()).toMatchObject({
      packageEntity: expect.objectContaining(packageData()),
    });
  });
});
