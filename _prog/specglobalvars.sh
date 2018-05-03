export blockly_orig="$scriptLib"/blockly
export SigBlockly_mod="$scriptLib"/SigBlockly

#modSource == original files to modify
export modSource="$blockly_orig"
#export modSource="$SigBlockly_mod"

export generatorTemplate=python
export generatorSource="$modSource"/generators/"$generatorTemplate"
export generatorSourceEntry="$modSource"/generators/"$generatorTemplate".js


export scriptModules="$scriptLib"/modules

export splice="$scriptModules"/splice
export spliceUnidiff="$scriptModules"/splice/unidiff

export spliceTmp="$safeTmp"/splice
export spliceTmpUnidiff="$spliceTmp"/unidiff

_prepare_splice() {
	mkdir -p "$spliceTmp"
	mkdir -p "$spliceTmpUnidiff"
}
