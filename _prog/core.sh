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
	
	cat "$3" | sed 's/$languageNameProper/'"$languageNameProper"'/g' | sed 's/$languageName/'"$languageName"'/g'
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
	
	modDestination="$scriptLocal"/templates/"$languageName"
	
	! mkdir -p "$modDestination" && _stop 1
	! mkdir -p "$modDestination"/demos/code && _stop 1
	! mkdir -p "$modDestination"/generators/"$languageName" && _stop 1
	
	rsync -q -ax --exclude "/.git"  "$modSource"/build.py "$modDestination"/
	
	rsync -q -ax --exclude "/.git"  "$modSource"/demos/code/index.html "$modDestination"/demos/code/
	rsync -q -ax --exclude "/.git"  "$modSource"/demos/code/code.js "$modDestination"/demos/code/
	
	rsync -q -ax --exclude "/.git" "$generatorSource"/. "$modDestination"/generators/"$languageName"/
	rsync -q -ax --exclude "/.git"  "$generatorSourceEntry" "$modDestination"/generators/"$languageName".js
	
	#Splice.
	mkdir -p "$spliceTmpUnidiff"/language
	_splice_generator_filter "$languageName" "$languageNameProper" "$spliceUnidiff"/language/build.py.patch > "$spliceTmpUnidiff"/language/build.py.patch
	
	mkdir -p "$spliceTmpUnidiff"/language/demos/code
	_splice_generator_filter "$languageName" "$languageNameProper" "$spliceUnidiff"/language/demos/code/code.js.patch > "$spliceTmpUnidiff"/language/demos/code/code.js.patch
	_splice_generator_filter "$languageName" "$languageNameProper" "$spliceUnidiff"/language/demos/code/index.html.patch > "$spliceTmpUnidiff"/language/demos/code/index.html.patch
	
	#Patch.
	! cd "$modDestination"/ && _stop 1
	! git check-ignore . && _stop 1
	
	_gitNew
	
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

