extends Node

# The species class separates the population into species by similarities between them.
#Todo:Revise the species class

class_name NN_Species

var agents : Array = []
var best_fitness : float = 0.0
var champ
var average_fitness : float = 0.0
var staleness : int = 0
var rep

const excess_coeff : float = 1.5
const weight_diff_coeff : float = 1.0
const compatibility_threshold : float = 1.3

# Constructor
func _init(agent):
	agents.append(agent)
	best_fitness = agent.fitness
	champ = agent.clone()
	rep = agent.brain
	self.add_child(champ)

func get_excess_disjoint(brain1, brain2):
	var matching = 0.0
	for i in brain1.genes:
		for j in brain2.genes:
			if (i.innovation == j.innovation):
				matching += 1
				break
	return (brain1.genes.size() + brain2.genes.size() - 2 * matching)

func average_weight_diff(brain1, brain2):
	if (brain1.genes.size() == 0 or brain2.genes.size() == 0):
		return 0.0
	
	var matching = 0
	var total_diff = 0
	for i in brain1.genes:
		for j in brain2.genes:
			if(i.innovation == j.innovation):
				matching += 1
				total_diff += abs(i.weight - j.weight)
				break
	
	if (matching == 0):
		return 100.0
	
	return total_diff / matching

func same_species(rep2):
	var compatibility
	var excess_and_disjoint = get_excess_disjoint(rep2, rep)
	var average_weight_diff = average_weight_diff(rep2, rep)
	
	var large_genome_normalizer = 1 * rep2.genes.size() - 20
	if (large_genome_normalizer < 1):
		large_genome_normalizer = 1
	
	compatibility = (excess_coeff * excess_and_disjoint / large_genome_normalizer) + (weight_diff_coeff * average_weight_diff)
	return (compatibility_threshold > compatibility)

func add_to_species(agent):
	agents.append(agent)

func sort_agents(a, b):
	if (a.fitness < b.fitness):
		return true
	return false

func sort_species():
	if(agents.size() == 0):
		staleness = 200
		return
	
	agents.sort_custom(self, "sort_agents")
	
	if(best_fitness == null or best_fitness == 0.0):
		best_fitness = agents[0].fitness
	
	if (agents[0].fitness > best_fitness):
		staleness = 0
		best_fitness = agents[0].fitness
		champ.queue_free()
		champ = agents[0].clone()
		rep = agents[0].brain
	else:
		staleness += 1

func set_average():
	var sum = 0
	for x in agents:
		sum += x.fitness
	if(agents.size() != 0):
		average_fitness = sum / agents.size()

func select_random_agent():
	var fitness_sum = 0
	for i in agents:
		fitness_sum += i.fitness
	
	var rand = agents[0].pop_ref.rng.randf_range(0, fitness_sum)
	var running_sum = 0
	
	for i in agents:
		running_sum += i.fitness
		if(running_sum > rand):
			return i
	
	return agents[0]

func give_bebe(innovation_history : Array):
	var bebe
	if (agents[0].pop_ref.rng.randf() < 0.25):
		bebe = select_random_agent().clone()
	else:
		var parent1 = select_random_agent()
		var parent2 = select_random_agent()
		
		if (parent1.fitness < parent2.fitness):
			bebe = parent2.crossover(parent1)
		else:
			bebe = parent1.crossover(parent2)
	
	bebe.brain.mutate(innovation_history)
	return bebe

func cull():
	if (agents.size() > 2):
		var x = ceil(agents.size() as float / 2)
		while x < agents.size():
			agents.remove(x)

func fitness_sharing():
	for i in agents:
		i.fitness /= agents.size()
