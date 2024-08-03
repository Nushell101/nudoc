def main [] {}

def 'main testing' [] {
    use ./numd

    let $path_simple_table = [z_examples 5_simple_nu_table simple_nu_table.md] | path join

    ['z_examples' '1_simple_markdown' 'simple_markdown.md']
    | path join
    | numd clear-outputs $in -o ($in | str replace 'markdown.md' 'markdown_with_no_output.md')

    glob z_examples/*/*.md --exclude [*/*_with_no_output* */*_customized*]
    | par-each {|file|
        numd clear-outputs $file --strip-markdown --echo
        | save -f (
            [z_examples 99_strip_markdown ($file | path parse | get stem | $in + '.nu')] | path join
        )
        numd run $file --no-backup --intermed-script $'($file)_intermed.nu'
    }
    | append (
        numd run $path_simple_table --table-width 20 --result-md-path (
            $path_simple_table | str replace 'simple_nu_table.md' 'simple_nu_table_customized_width20.md'
        )
    )
    | append (
        numd run $path_simple_table --config-path 'numd_example_config.yaml' --result-md-path (
            $path_simple_table | str replace 'simple_nu_table.md' 'simple_nu_table_customized_example_config.md'
        )
    )
    | append (numd run README.md --no-backup)
}

def 'main release' [] {
    let $description = gh repo view --json description | from json | get description
    let $tag = git tag | lines | sort -n | last | split row '.' | into int | update 2 {$in + 1} | str join '.'

    open nupm.nuon
    | update description ($description | str replace 'numd - ' '')
    | update version $tag
    | to nuon --indent 2
    | save --force --raw nupm.nuon

    open README.md -r
    | lines
    | update 0 ('<h1 align="center">' + $description + '</h1>')
    | str join (char nl)
    | $in + (char nl)
    | save -r README.md -f

    # prettier README.md -w

    # use nupm
    # nupm install --force --path .

    git add nupm.nuon
    git commit -m $'($tag) nupm version'
    git tag $tag
    git push origin $tag
}
