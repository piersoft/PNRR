
class BubbleChart
  constructor: (data) ->
    @data = data
    @width = 960
    @height = @width/2

    @tooltip = CustomTooltip("tooltip", 200)

    # locations the nodes will move towards
    # depending on which view is currently being
    # used
    @center = {x: @width / 2, y: @height / 2}
    @year_centers = {
      "Digitalizzazione, innovazione, competitivita' e cultura": {x: @width / 5+10, y: @height / 2},
      "Rivoluzione verde e transizione ecologica": {x: @width / 4 + 90, y: @height / 2},
      "Infrastrutture per una mobilita' sostenibile": {x: @width / 2-50, y: @height / 2},
      "Istruzione e ricerca": {x: @width/2+50, y: @height / 2},
      "Coesione e inclusione": {x: @width - 280, y: @height / 2},
      "Salute": {x: @width - 200, y: @height / 2},

    }

    # used when setting up force and
    # moving around nodes
    @layout_gravity = -0.01
    @damper = 0.1

    # these will be set in create_nodes and create_vis
    @vis = null
    @nodes = []
    @force = null
    @circles = null

    # nice looking colors - no reason to buck the trend
    @fill_color = d3.scale.ordinal()
      .domain(["0","1","3","4","5","6"])
      .range(["#7aa25c", "#FFa500", "#7aa2FF","#f80000","#f002a0","#619fdc"])

    # use the max total_amount in the data as the max in the scale's domain
    max_amount = d3.max(@data, (d) -> parseInt(d.total_amount))
    @radius_scale = d3.scale.pow().exponent(0.5).domain([0, max_amount]).range([2, 85])

    this.create_nodes()
    this.create_vis()

  # create node objects from original data
  # that will serve as the data behind each
  # bubble in the vis, then add each node
  # to @nodes to be used later
  create_nodes: () =>
    @data.forEach (d) =>
      node = {
        id: d.id
        radius: @radius_scale(parseInt(d.total_amount)*0.6)
        value: d.total_amount
        name: d.grant_title
        org: d.organization
        group: d.group
        year: d.start_year
        x: Math.random() * 900
        y: Math.random() * 800
      }
      @nodes.push node

    @nodes.sort (a,b) -> b.value - a.value


  # create svg at #vis and then
  # create circle representation for each node
  create_vis: () =>
    @vis = d3.select("#vis")
      .append("div")
      .classed("svg-container", true)
      .append("svg")
      .attr("preserveAspectRatio", "xMinYMin meet")
      .attr("viewBox", "0 0 960 540")
      .classed("svg-content-responsive", true)
      .attr("id", "svg_vis")



    @circles = @vis.selectAll("circle")
      .data(@nodes, (d) -> d.id)

    # used because we need 'this' in the
    # mouse callbacks
    that = this

    # radius will be set to 0 initially.
    # see transition below
    @circles.enter().append("circle")
      .attr("r", 0)
      .attr("fill", (d) => @fill_color(d.group))
      .attr("stroke-width", 2)
      .attr("stroke", (d) => d3.rgb(@fill_color(d.group)).darker())
      .attr("id", (d) -> "bubble_#{d.id}")
      .on("mouseover", (d,i) -> that.show_details(d,i,this))
      .on("mouseout", (d,i) -> that.hide_details(d,i,this))

    # Fancy transition to make bubbles appear, ending with the
    # correct radius
    @circles.transition().duration(2000).attr("r", (d) -> d.radius)


  # Charge function that is called for each node.
  # Charge is proportional to the diameter of the
  # circle (which is stored in the radius attribute
  # of the circle's associated data.
  # This is done to allow for accurate collision
  # detection with nodes of different sizes.
  # Charge is negative because we want nodes to
  # repel.
  # Dividing by 8 scales down the charge to be
  # appropriate for the visualization dimensions.
  charge: (d) ->
    -Math.pow(d.radius, 2.0) / 13

  # Starts up the force layout with
  # the default values
  start: () =>
    @force = d3.layout.force()
      .nodes(@nodes)
      .size([@width, @height])

  # Sets up force layout to display
  # all nodes in one circle.
  display_group_all: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_center(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.hide_years()

  # Moves all circles towards the @center
  # of the visualization
  move_towards_center: (alpha) =>
    (d) =>
      d.x = d.x + (@center.x - d.x) * (@damper + 0.02) * alpha
      d.y = d.y + (@center.y - d.y) * (@damper + 0.02) * alpha

  # sets the display of bubbles to be separated
  # into each year. Does this by calling move_towards_year
  display_by_year: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_year(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.display_years()

  # move all circles to their associated @year_centers
  move_towards_year: (alpha) =>
    (d) =>
      target = @year_centers[d.year]
      d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 1.1
      d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 1.1


  # Method to display year titles
  display_years: () =>
    years_x = {"Digitalizzazione": @width / 5-90, "Rivoluzione verde": @width / 4 +40, "Infrastrutture per mobilita'": @width / 2-30, "Istruzione e ricerca": @width/2+110,"Coesione e inclusione": @width - 220,"Salute": @width - 100}
    years_data = d3.keys(years_x)
    years_group = {"Digitalizzazione": "#FFa500","Rivoluzione verde":"#7aa25c","Infrastrutture per mobilita'":"#619fdc","Istruzione e ricerca":"#f80000","Coesione e inclusione":"#ed72e7","Salute":"#0000FF"}
    years = @vis.selectAll(".years")
      .data(years_data)

    years.enter().append("text")
      .attr("class", "year")
      .attr("x", (d) => years_x[d] )
      .attr("y", 40)
      .attr("text-anchor", "middle")
      .attr("fill",(d) => years_group[d])
      .text((d) -> d)

  # Method to hide year titiles
  hide_years: () =>
    years = @vis.selectAll(".year").remove()

  show_details: (data, i, element) =>
    d3.select(element).attr("stroke", "#f80000")
    content = "<span class=\"name\">COMPONENTE:</span><span class=\"value\"> #{data.name}</span><br/>"
    content +="<span class=\"name\">IMPORTO</span><span class=\"value\"> #{data.value}</span><br/>"
    content +="<span class=\"name\">MISSIONE</span><span class=\"value\"> #{data.year}</span>"
    @tooltip.showTooltip(content,d3.event)


  hide_details: (data, i, element) =>
    d3.select(element).attr("stroke", (d) => d3.rgb(@fill_color(d.group)).darker())
    @tooltip.hideTooltip()


root = exports ? this

$ ->
  chart = null

  render_vis = (csv) ->
    chart = new BubbleChart csv
    chart.start()
    root.display_all()
  root.display_all = () =>
    chart.display_group_all()
  root.display_year = () =>
    chart.display_by_year()
  root.toggle_view = (view_type) =>
    if view_type == 'year'
      root.display_year()
    else
      root.display_all()

  d3.csv "https://docs.google.com/spreadsheets/d/e/2PACX-1vSjMFew4pG83xZSPKbktSZj47GaBLY1PAFqNvT3RjBod82OWH2bgeJtSN4Rutf_c5SoUpYtsIePw3al/pub?gid=44335948&single=true&output=csv", render_vis
