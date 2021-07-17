extends Node

# The class that holds all of the NN.
# A population means a lot of agents doing whatever.

class_name NN_Population

var rng = RandomNumberGenerator.new()

var pop := [] # The actual population

var best_agent
var best_score := 0.0
var gen := 0
var innovation_history := []
var gen_agents := []
var species := []
var kill_stale := false
var all_inactive := false
var checker := 1

var next_connection_number := 0

var MASS_EXTINCTION := false

signal generation_changed(gen)

# A constructor would make this very hard to extend, so call it like My_Population.new().generate(a, b, c, d)
func generate(size : int):
	rng.randomize()
	for i in range(size):
		pop.append(create_agent())
		pop[i].id = i
		pop[i].brain.generate_network()
		pop[i].brain.mutate(innovation_history)
		add_child(pop[i])
	return self

# Creates a new agent
func add_agent():
	pop.append(create_agent())
	pop.back().id = pop.size() - 1
	pop.back().brain.generate_network()
	pop.back().brain.mutate(innovation_history)
	add_child(pop.back())
# Virtual function that must be replaced by the user. Don't use generate_internal, however.
func create_agent():
	return NN_Agent.new().generate_internal(4, 4, false, self)

func _physics_process(delta):
	checker -= delta
	if checker <= 0:
		var alive = false
		for i in pop:
			if i.active:
				alive = true
				break
		all_inactive = not alive
		checker += 1

#Todo:Actually normalize update_alive() and feed_forward()
func update_alive():
	for i in pop:
		i.think()

# Sets the best agent on each species, based on score.
func set_best_agent():
	var temp_best = species[0].agents[0]
	temp_best.gen = gen
	if(temp_best.fitness > best_score):
		gen_agents.append(temp_best.clone())
		best_score = temp_best.fitness
		best_agent = gen_agents.back()

# Segregates all agents into species.
func speciate():
	for i in species:
		i.agents.clear()
	
	for i in pop:
		var species_found = false
		for j in species:
			if (j.same_species(i.brain)):
				j.add_to_species(i)
				species_found = true
				break
		if (!species_found):
			species.append(NN_Species.new(i))

# Calculates the fitness of every agent.
func calculate_fitness():
	for i in pop:
		i.calculate_fitness()

# Sorts the species based on the score of each agent.
func sort_species():
	for i in species:
		i.sort_species()
	
	var temp = []
	for i in species:
		var maximum = -INF
		var max_index = 0
		for j in range(species.size()):
			if (species[j].best_fitness > maximum):
				maximum = species[j].best_fitness
				max_index = j
		
		temp.append(species[max_index])
		species.remove(max_index)
	
	species = temp

# Genocide all the stale species. I don't know if this is actually necessary.
func kill_stale_species():
	var i = 0
	while (i < species.size()):
		if (species[i].staleness >= 15):
			species.remove(i)
			i -= 1
		i += 1

# Gets the average fitness.
func get_avg_fitness_sum():
	var average_sum = 0
	for i in species:
		average_sum += i.average_fitness
	return average_sum

# Genocide all the species doing poorly, so we can Charles Darwin the population.
func kill_bad_species():
	var i = 0
	var average_sum = get_avg_fitness_sum()
	while i < species.size():
		if (species[i].average_fitness / average_sum * pop.size() < 1):
			species.remove(i)
			i -= 1
		i += 1

# Thanos snaps the population.
func cull_species():
	for i in species:
		i.cull()
		i.fitness_sharing()
		i.set_average()

# Genocides the population, but 5 of them.
func mass_extinction():
	for _i in range(5, species.size()):
		species[5].queue_free()
	while(species.size() > 5):
		species.remove(5)

# The actual Charles Darwin stuff.
func natural_selection():
	speciate()
	calculate_fitness()
	sort_species()
	if(MASS_EXTINCTION):
		mass_extinction()
		MASS_EXTINCTION = false
	cull_species()
	set_best_agent()
	if (kill_stale):
		kill_stale_species()
	kill_bad_species()
	
	var average_sum = get_avg_fitness_sum()
	var children = []
	
	# It also makes the next generation, not all is war crimes and blood.
	
	for i in species:
		children.append(i.champ.clone())
		var no_of_children = floor(i.average_fitness / average_sum * pop.size()) - 1
		for _j in range(no_of_children):
			children.append(i.give_bebe(innovation_history))
	
	while(children.size() < pop.size()):
		children.append(species[0].give_bebe(innovation_history))
	
	for i in pop:
		i.get_parent().remove_child(i)
	
	pop = children
	gen += 1
	
	for i in pop:
		add_child(i)
		i.brain.generate_network()
	
	emit_signal("generation_changed", gen)
