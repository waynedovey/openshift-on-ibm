#!/bin/bash

# ANSIBLE0006: Using command rather than module
#   we have a few use cases where we need to use curl and rsync
# ANSIBLE0016: Tasks that run when changed should likely be handlers
#   this requires refactoring roles, skipping for now
# ANSIBLE0012: Commands should not change things if nothing needs doing
#   this requires refactoring roles, skipping for now
SKIPLIST="ANSIBLE0006,ANSIBLE0016,ANSIBLE0012"

# lint the playbooks separately to avoid linting the roles multiple times
for DIR in tasks playbooks; do
    if [ -d "$DIR" ]; then
        pushd $DIR
        for playbook in `find . -type f -regex '.*\.y[a]?ml'`; do
            ansible-lint -vvv -x $SKIPLIST $playbook || lint_error=1
        done
        popd
    fi
done

# lint all the possible roles
# Due to https://github.com/willthames/ansible-lint/issues/210, the roles
# directories need to contain a trailing slash at the end of the path.
if [ -d ./roles ]; then
    for rolesdir in `find ./roles -maxdepth 1 -type d`; do
        ansible-lint -vvv -x $SKIPLIST $rolesdir/ || lint_error=1
    done
fi

# exit with 1 if we had a least an error or warning.
if [[ -n "$lint_error" ]]; then
    exit 1;
fi
