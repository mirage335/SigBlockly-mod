##### Core


_update_SigBlockly() {
	local localFunctionEntryPWD
	localFunctionEntryPWD="$PWD"
	
	! cd "$SigBlockly_mod" && return 1
	
	git reset --hard
	
	#git pull upstream master
	
	#https://stackoverflow.com/questions/15232000/git-ignore-files-during-merge
	#https://stackoverflow.com/questions/41101998/git-checkout-vs-git-checkout
	git merge --no-ff --no-commit upstream/master
	git reset HEAD LICENSE
	git reset HEAD README.md
	git checkout -- LICENSE
	git checkout -- README.md
	#git commit -m "merged <merge-branch>"
	
	
	cd "$localFunctionEntryPWD"
}

#"$1" == $modSource
#"$2" == $modDestination
#"$3" == path
_modTransfer() {
	rsync -q -ax --exclude "/.git" "$1"/"$3" "$2"/"$3"
}

#languageName == "$1"
#languageNameProper == "$2"
#spliceCodeUnidiff == "$3"
_splice_generator_filter() {
	local languageName
	languageName="$1"
	local languageNameProper
	languageNameProper="$2"
	local spliceCodeUnidiff
	spliceCodeUnidiff="$3"
	
	sed -i 's/$languageNameProper/'"$languageNameProper"'/g' "$3"
	sed -i 's/$languageName/'"$languageName"'/g' "$3"
}


_construct_generator_sequence() {
	_start
	_prepare_splice
	
	local localFunctionEntryPWD
	localFunctionEntryPWD="$PWD"
	
	local languageName
	languageName="$1"
	local languageNameProper
	languageNameProper="$2"
	
	export modDestination="$scriptLocal"/templates/"$languageName"
	
	
	#Files.
	! mkdir -p "$modDestination" && _stop 1
	! mkdir -p "$modDestination"/demos/code && _stop 1
	! mkdir -p "$modDestination"/generators && _stop 1
	
	_modTransfer "$modSource" "$modDestination" build.py
	
	_modTransfer "$modSource" "$modDestination" demos/code/index.html
	_modTransfer "$modSource" "$modDestination" demos/code/code.js
	
	_modTransfer "$modSource" "$modDestination" "$generatorSource"/
	_modTransfer "$modSource" "$modDestination" "$generatorSource".js
	
	mv "$modDestination"/"$generatorSource" "$modDestination"/generators/"$languageName"
	mv "$modDestination"/"$generatorSource".js "$modDestination"/generators/"$languageName".js
	
	#Splice.
	_modTransfer "$spliceUnidiff" "$spliceTmpUnidiff" .
	
	_splice_generator_filter "$languageName" "$languageNameProper" "$spliceTmpUnidiff"/language/build.py.patch
	_splice_generator_filter "$languageName" "$languageNameProper" "$spliceTmpUnidiff"/language/demos/code/code.js.patch
	_splice_generator_filter "$languageName" "$languageNameProper" "$spliceTmpUnidiff"/language/demos/code/index.html.patch
	
	#Track.
	! cd "$modDestination"/ && _stop 1
	! git check-ignore . && _stop 1
	
	_gitNew
	
	#Substitute.
	sed -i 's/Blockly.Generator('\'''"$modLanguageNameProper"''\'')/Blockly.Generator('\'''"$languageName"''\'')/g' "$modDestination"/generators/"$languageName".js
	find "$modDestination"/generators/"$languageName" -name '*.js' -exec sed -i 's/Blockly\.'"$modLanguageNameProper"'/Blockly\.'"$languageName"'/g' {} \;
	
	#Patch.
	git apply "$spliceTmpUnidiff"/language/build.py.patch
	git apply "$spliceTmpUnidiff"/language/demos/code/code.js.patch
	git apply "$spliceTmpUnidiff"/language/demos/code/index.html.patch
	
	
	
	cd "$localFunctionEntryPWD"
	
	
	_stop
}

_construct_generator() {
	"$scriptAbsoluteLocation" _construct_generator_sequence "$@"
}

_construct_generator_c() {
	_construct_generator "c" "C" "$@"
}

