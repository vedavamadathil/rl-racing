#ifndef CAR_H_
#define CAR_H_

// Godot headers
#include <Godot.hpp>
#include <KinematicBody2D.hpp>
#include <KinematicCollision2D.hpp>
#include <NodePath.hpp>
#include <Input.hpp>
#include <GlobalConstants.hpp>

namespace godot {

class Agent : public KinematicBody2D {
	double velocity;

	int spawns;

	// Instantiate as a Godot class
	GODOT_CLASS(Agent, KinematicBody2D);

public:
	// Accessible from GDScript classes
	NodePath spawn;

	double angle;
	
	// Methods
	static void _register_methods();

	Agent();
	~Agent();

	void rand_reset();

	void _init();

	void _ready();
	void _process(float delta);

	static const double min_vel;
	static const double max_vel;
	
	static const double acceleration;
	static const double brake;
	static const double drag;
};

}

#endif
