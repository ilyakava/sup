# should be run in the local rails console
# requires installing graphviz

installed_graphviz = `which dot`
fail 'install graphviz from: http://www.graphviz.org/Download.php' if installed_graphviz.empty?

purple = '#6a0bc1'
light_gray = '#dbdbdb'

# ### people connected to each other via groups
File.open('./doc/graph.gv', 'w') do |f|
  switch_node_itr = 1
  dict = {}
  edges = []

  f.puts %(graph switches {  )
  f.puts %(
  node [
    shape=box,
    color="#{light_gray}",
    fontname="Helvetica.",
    fontsize=8
  ];
    )

  # create dict used by edge lines and write node lines
  Member.all.each do |member|
    switch_node_name = "sw#{switch_node_itr}"
    dict[member.id] = switch_node_name
    f.puts %(    #{switch_node_name} [ label="#{member.name}" ];    )
    switch_node_itr += 1
  end

  # create edge lines
  Group.all.each do |group|
    pairwise_combos = group.members.pluck(:id).combination(2)
    pairwise_combos.each do |c|
      edges << %(      #{dict[c.first]} -- #{dict[c.last]} [color="#{purple}"];      )
    end
  end

  # write edge lines
  edges.uniq.each do |l|
    f.puts l
  end
  f.puts %(}  )
end

`dot -Tpng doc/graph.gv -o doc/graph.png`
`rm doc/graph.gv`
