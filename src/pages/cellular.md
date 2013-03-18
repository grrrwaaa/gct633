title: Cellular systems and lattice models


# Cellular systems and lattice models

Provides an interesting continuum between non-living (such as molecules in crystal and metalline structures) and living (such as cells of a multi-cellular organism). The main difference is that, although both begin with more or less 'the same program', in living material the individual behavior of each cell specializes according to early conditions. This is important for *developmental biology*. Of course, computational cellular systems are far, far simpler than biological cells; but still draw from this inpsiration. The CA model was propsed by Stanislaw Ulam and used by von Neumann to demonstrate machines that can reproduce themselves; a more concise example being proposed by [Christopher Langton](http://www.youtube.com/watch?v=2iDc4C6vbcc) decades later, itself later [improved upon using artificial evolutionary techniques](http://www.youtube.com/watch?v=vbpoTZlNTiw&NR=1&feature=endscreen).

[The wikibooks on CA](http://www.interciencia.es/PDF/WikipediaBooks/CellAutomata.pdf).

The essential components that define a cellular system:

- **Cellular space:** A collection of cells arranged into a discrete lattice, such as a 2D grid. 
- **Cell states:** The information representing the current condition of a cell. In *Game of Life* this is either 0 or 1, but in other systems the state could be represented by an n-tuple of values, or something more complex. The set of possible states could be defined as finite or unbounded.
- **Initial conditions:** What state the cells are in at the start of the simulation.
- **Neighborhood:** The set of adjacent/nearby cells that can directly influence a particular cell. In *Game of Life* these are the 8 side and corner neighbors (the *Moore* neighborhood). In other systems it could be expressed as a radius or range.
- **State transition function:** The rule that a cell follows to update its state, which depends on the current state and the state of the neighborhood.
- **Time axis:** The cells are generally updated in a discrete fashion, which may be synchronous (all cells update simultaneously) or asynchronous (cells update separately, e.g. in a probabilistic manner).
- **Boundary conditions:** What happens to cells at the edges. A periodic boundary 'wraps around' to the opposite edge; a static boundary always has the same state, a copying or reflective boundary mirrors the neighbor state, etc.

## Cellular automata

The mathematical notion of *automaton* indicates a discrete-time system with finite set of possible states, a finite number of inputs, a finite number of outputs, and a transition rule which gives the state at the next step in terms of the state and inputs at the previous step.

A *CA* applies this notion to a cellular space. It has discrete time, finite neighborhood (inputs), finite state set (often represented as integers) and synchronous update. The transition rule (or CA rule) is usually deterministic, giving a cell state[t+1] as a function of the states[t] of itself and neighbours; and all cells use the same transition rule. 

The space itself is usually 1D, 2D or 3D, but rarely greater. Wolfram performed most of his research using 1D CAs, such as the 'rule 30' CA below, whose evolution bears similarities with some shell patterns. The most famous CA *Game of Life* is 2D, which is so popular that people have written [Turing machines](http://www.youtube.com/watch?v=My8AsV7bA94) and [Game of Life](http://www.youtube.com/watch?v=xP5-iIeKXE8) in terms of it. [Over here a 3D cellular automaton is taking over Minecraft](https://www.youtube.com/watch?v=wNypW-aSCmE), and [here is a self-replicating computer in 3D](http://www.youtube.com/watch?v=PBXO_6Jn1fs).

![Evolution of a 1D CA: rule 30](img/ca_shells.jpg)

Wolfram divided CA into four classes, according to their long-term behavior:

- **Class 1** - stable. Evolves to homogeneous state.
- **Class 2** - cyclic. Evolves to simple separated periodic structures. Local changes to the initial pattern tend to remain local
- **Class 3** - chaotic. Any stable structures that appear are quickly destroyed by the surrounding noise. Local changes to the initial pattern tend to spread indefinitely
- **Class 4** - complex. Local changes to the initial pattern may spread indefinitely. Wolfram has conjectured that many, if not all class 4 cellular automata are capable of universal computation.

### Conway's Game of Life

The *Game of Life* CA is an example of a *outer totalistic* CA: The spatial directions of cells do not matter, only the total value of all neighbors is used, along with the current value of teh cell itself. The transition rule for a cell can be stated concisely as follows:

- If the current state is 1 ("alive"):
	- If the neighbor total is less than 2: New state is 0 ("death by loneliness")
	- Else if the neighbor total is greater than 3: New state is 0 ("death by overcrowding")
	- Else: State remains the same ("alive")
- If the current state is 0 ("dead"):
	- If the neigbor total is exactly 3: New state is 1 ("reproduction")
	- Else: State remains the same ("dead")
	
Or, in Lua:

```lua
if state == 1 then
	-- currently alive
	if neighbors < 2 then
		-- death by loneliness
		state = 0
	elseif neighbors > 3 then
		-- death by overcrowding
		state = 0
	end
else
	-- currently dead
	if neighbors == 3 then
		-- birth by reproduction
		state = 1
	end
end
```

The Game of Life produces easily recognizable higher-level formations including stable objects, oscillatory objects, mobile objects and objects that produce or consume others, for example, which have been called 'ponds', 'gliders', 'eaters', 'glider guns' and so on. In Wolfram's terms, it is *Class 4* CA.

Note that these rules mean that the Game of Life is not reversible: from a given state it is not possible to determine the previous state.

### Implementation

If the cells are densely packed into a regular lattice structure, such as a 2D grid, they can efficiently be represented as *array* memory blocks. The state of a cell can be represented by a number, so an array of integers works well. A way to index this array memory to read or write a cell coordinate will be useful.

In theory the transition rule can be represented as a *look-up table*, however above a certain number of states and neighbors the size of this table would become astronomical (k states raised to the power of k neighbor states raised to the power of n neighbors; for a 3-state, 3-neighbor system this requires 7 billon rules!), so a procedural implementation is preferable. CAs may use bit-wise operators to implement the transition rules in a hardware-optimized way, but we will use regular ```if``` statements, like the above, for clarity. 

One complication is that the states of the whole lattice must update synchronously. That means: when one cell changes, all cells should change. This is not easy to achieve in most computing systems today, which mostly follow instructions one at a time (with only limited parallelism). A naive implementation will thus update cells one at a time, and the neighborhood of a particular cell will contain both 'past' and 'future' states. One way to work around this is to maintain two copies of the lattice; one for the 'past' states, and one for the 'future' states. The transition rule always reads from the 'past' lattice, and always writes to the 'future' lattice. After all cells are updated, either the 'future' is copied to the 'past', or the 'future' and 'past' lattices are swapped, since the future of yesterday is the past of tomorrow. 

> This technique is called *double-buffering*, and is widely used in software systems where a parallel process interacts with a serial machine. It is used to render graphics to the screen, for example.


## Variations

### Non-homogenous CA

The rule is not the same for all cells / for all time steps. Spatial non-homogeneity can be interesting to simulate different geographies (such as boundaries). Temporal non-homogeneity can be used to perform a sequence of different filters. 

Or perhaps the neighborhood selection may change between updates (also see particle CA below).

These can be implemented by changing the function used in the transition rule, or by extending the state set to accommodate the differences. Changing the function is usually easier to implement and understand.

### Probabilistic/Stochastic CA

In this case the transition rule is not deterministic, but includes some random factor. For example, a probability can be assigned to each successor state according to the prior states. 

Take a look at the [Forest Fire CA example](https://github.com/grrrwaaa/gct753/blob/master/ca_2D_forest_fire.lua), and try changing the probabilities to see how it behaves.

Also try modifying Game of Life to include a very small probability of randomly changing state, for example.

### Particle CA, Lattice-Gas Automata and Block Rule CA

The cell states represent the presence (or absence) of particles in a cell, and transition rules represent how particles move across cells. Generally the transition rule must preserve the quantity of particles. The elementary 1D traffic CA (rule 184) is a simple particle CA. 

An implementation option is to use *block rules*, which consider small regions at a time, rather than individual cells; e.g. a 2x2 region of cells in a 2D CA (the *Margolus neighborhood*). To handle the boundaries between blocks, the regions are shifted between each application ([see wikipedia](http://en.wikipedia.org/wiki/Block_cellular_automaton)). 

![Margolus neigborhood](img/mnhood.gif)

Note that a block rule CA does not need to be implemented with two buffers, since each block updates synchronously internally, and independently externally.

More example block CAs [here](http://psoup.math.wisc.edu/mcell/rullex_marg.html) -- many of these are implemented [in the example script here](https://github.com/grrrwaaa/gct753/blob/master/ca_2D_block_rules.lua). 

In 1969, German computer pioneer (and painter) Konrad Zuse published his book [Calculating Space](ftp://ftp.idsia.ch/pub/juergen/zuserechnenderraum.pdf), proposing that the physical laws of the universe are discrete by nature, and that the entire universe is the output of a deterministic computation on a single cellular automaton. This became the foundation of the field of study called *digital physics*. Zuse's first model is a 3D particle CA.

![Zuse's vision of nature](img/zuse.jpg)

### Asynchronous CA

Instead of updating all cells at once, update one cell at a time, according to some update policy. The same choices can be applied per-block in a block-rule CA.

- A fixed update policy, such as linear scan or pre-determined path, is orderly, but may introduce artifacts (related to the *double-buffering* pattern). 
- A *probabilistic asynchronous CA* chooses the next active cell according to a random selection (related to the Monte Carlo methods described below).
- A multi-rate CA (self-clocked) updates each cell according to a clock period that varies from cell to cell. The clock period could also be affected by neighbors, to achieve *entrainment* effects.
- A *mobile CA* chooses a related cell (such as one of the neighbors) of the current active cell as the next active cell. So in addition to choosing a new state for the cell, the transition rule must also choose how to move the active cell. This could also be partly probabilistic.

[Langton's Ant](http://en.wikipedia.org/wiki/Langton%27s_ant) is a mobile CA in a 2D, two-state space, with very simple rules:

- At a white square, turn 90° right, flip the color of the square, move forward one unit
- At a black square, turn 90° left, flip the color of the square, move forward one unit

[See the script](https://github.com/grrrwaaa/gct753/blob/master/ca_2D_langtons_ant.lua) in the repo, and the [original video by Christopher Langton](http://www.youtube.com/watch?v=w6XQQhCgq5c), including examples of multiple ants (and music by the Vasulkas). Note that Langton's Ant, and other related Turmites, are closely related to the turtle graphics often used for L-systems.

### Continuous automata

**Continuous states:** In this case, the states are not discrete but belong to a continuum, such as the linear range 0..1. Instead of using a discrete transition rule or lookup table, continuous functions can be used (or combined with discrete rules such as comparisons). Continuous automata can show liquid and diffusive effects.

**Continuous neighborhood:** Instead of accumulating whole neighbor cells, apply a *kernel* region, weighting cells according to the degree that they fall under a radius, or by distance.

[SmoothLife](http://www.youtube.com/playlist?list=PL69EDA11384365494) still uses a discrete grid, but both the kernel and transition functions are adjusted for smooth, continuous values; it removes the discrete bias and leads to fascinating results. [Another implementaton](http://www.youtube.com/watch?v=l7t8LtdBAV8). [Taken to 3D](http://www.youtube.com/watch?v=zA857JdUn9o&list=PL69EDA11384365494&index=46).

Can there be continuous space automata? If time were also continuous, they would simply be differential equations.

#### Reaction Diffusion

The reaction-diffusion model was proposed by Turing to describe embryo development and pattern-generation; it is still used today in CG. [Turing, A. The Chemical Basic for Morphogenesis.](http://www.dna.caltech.edu/courses/cs191/paperscs191/turing.pdf). RD systems and other differential equation systems can be approximated using continuous automata.

![The Gray-Scott parameter map](img/xmorphia-parameter-map.jpg)

One approach to simulating RD using CA is the *Gray-Scott* model, as described in [Pearson, J. E. Complex Patterns in a Simple System](http://arxiv.org/pdf/patt-sol/9304003.pdf). There is [a wonderful archive of this model at this webpage](http://mrob.com/pub/comp/xmorphia/), including many great video examples of the [u-skate world](http://www.youtube.com/watch?v=F5oKgVZ6bTk), and even [u-skate in 3D](http://www.youtube.com/watch?v=B03lcPEmSOQ).

### Statistical and unbounded state models

The *Ising model* of ferromagnetism in statistical mechanics can also be simulated in a *Monte Carlo* fashion. Each site (cell) has either positive or negative spin (we can encode that as 0 or 1 value). At each time step, consider a site at random, and evaluate the probability of changing state. If changing state moves the site toward energetic equilibrium with neighbors (determined according to the Hamiltonian of the site) , then the change is made. Otherwise, the change is made only with a small probability that is dependent on the energetic difference and overall temperature. Thus at high temperatures, the system remains noisy, while at low temperatures it gradually self-organizes into all sites with equal spin.

It is also related to the *contact process* model, which has been used to simulate the spread of infection: infected sites become healthy at a constant rate, while healthy sites become infected at a rate proportional to the number infected neighbor (see also the *HodgePodge* simulation). This can be extented to multiple states for a multitype contact process. The *voter model* similarly simulates the changing of opinion in social groups. 

The cellular *Potts model* (also known as the *Glazier-Graner* model) generalizes these to allow more than two site states, and in some cases, an unbounded number of possible site states; however it still utilizes the notion of statistical movement toward neighbor equilibrium to drive change, though the definition of a local Hamiltonian. Variations have been used to model grain growth, foam, fluid flow, chemotaxis, biological cells, and even the developmental cycle of whole organisms. Note that in this field, the term *cell* is used not to refer to a site on the lattice, but to a whole group of connected sites that share the same state. So in modeling foam, a *cell* represents a single bubble, and is made of one or more *sites*. Most changes therefore happen at the boundaries between these cells.

Stan Marée used this model to simulate the whole life cycle of [Dictyostelium discoideum](http://www-binf.bio.uu.nl/stan/Thesis/).

### Multi-Scale Turing Patterns

[Jonathan McCabe's cyclic multi-scale Turing patterns](http://www.jonathanmccabe.com/), and a [commentary by Mitchell Whitelaw](http://teemingvoid.blogspot.kr/2007/02/jonathan-mccabe-very-cellular-automata.html)

Some of these systems share resemblance with analog video feedback ([example](http://www.youtube.com/watch?v=hDYEVv9t32U), [example](http://www.youtube.com/watch?v=Uw5onuS2_mw)), which has been exploited by earlier media artists (notably the Steiner and Woody Vasulka). 