#!/bin/bash

VKPR_SCRIPTS=~/.vkpr/src

source $VKPR_SCRIPTS/log.sh
source $VKPR_SCRIPTS/var.sh
source $VKPR_SCRIPTS/helper.sh

. "$(dirname "$0")"/unix/formula/formula.sh --source-only

runFormula
