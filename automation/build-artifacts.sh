#!/bin/bash -xe

SUFFIX=".git$(git rev-parse --short HEAD)"

# remove any previous artifacts
rm -rf output
rm -f ./*tar.gz


for package in ovirt-live-artwork ovirt-engine-setup-plugin-live
do
# build tarball
    pushd "${package}"
    autoreconf -ivf
    ./configure
    make clean
    make dist
    mv "${package}"-*.tar.gz ../
    popd

    # create the src.rpm
    rpmbuild \
        -D "_srcrpmdir $PWD/output" \
        -D "_topmdir $PWD/rpmbuild" \
        -D "release_suffix ${SUFFIX}" \
        -ts "${package}"-*.tar.gz

    # install any build requirements
    yum-builddep output/"${package}"-*src.rpm

    # create the rpms
    rpmbuild \
        -D "_rpmdir $PWD/output" \
        -D "_topmdir $PWD/rpmbuild" \
        -D "release_suffix ${SUFFIX}" \
        --rebuild output/"${package}"-*src.rpm
done

# Store any relevant artifacts in exported-artifacts for the ci system to
# archive
[[ -d exported-artifacts ]] || mkdir -p exported-artifacts
find output -iname \*rpm -exec mv "{}" exported-artifacts/ \;
mv ./*tar.gz exported-artifacts/
