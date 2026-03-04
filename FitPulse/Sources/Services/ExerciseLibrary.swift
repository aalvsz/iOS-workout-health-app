import Foundation

struct ExerciseLibrary {

    // MARK: - All Exercises

    static let allExercises: [ExerciseLibraryItem] = chest + back + shoulders + biceps + triceps + legs + core + fullBody

    // MARK: - Chest (8)

    private static let chest: [ExerciseLibraryItem] = [
        ExerciseLibraryItem(
            name: "Barbell Bench Press",
            description: "The foundational chest builder performed lying on a flat bench pressing a barbell.",
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders],
            equipment: .barbell,
            difficulty: .intermediate,
            instructions: [
                "Lie flat on the bench with eyes under the bar, grip slightly wider than shoulder-width.",
                "Unrack and lower the bar to mid-chest with elbows at roughly 45 degrees.",
                "Press the bar back up to full lockout while driving your feet into the floor."
            ],
            commonMistakes: [
                "Flaring elbows to 90 degrees, increasing shoulder stress.",
                "Bouncing the bar off the chest instead of controlling the descent.",
                "Lifting hips off the bench to cheat the weight up."
            ]
        ),
        ExerciseLibraryItem(
            name: "Incline Dumbbell Press",
            description: "A dumbbell press on an inclined bench emphasizing the upper chest.",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps],
            equipment: .dumbbell,
            difficulty: .intermediate,
            instructions: [
                "Set the bench to 30-45 degrees and sit back with a dumbbell in each hand at shoulder height.",
                "Press the dumbbells up and slightly inward until arms are extended.",
                "Lower under control until upper arms are parallel to the floor."
            ],
            commonMistakes: [
                "Setting the incline too steep, turning it into a shoulder press.",
                "Letting the dumbbells drift too far forward at the top.",
                "Using momentum by arching excessively off the bench."
            ]
        ),
        ExerciseLibraryItem(
            name: "Cable Fly",
            description: "An isolation movement using cables to maintain constant tension on the chest.",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders],
            equipment: .cableMachine,
            difficulty: .beginner,
            instructions: [
                "Set both pulleys to shoulder height and grab each handle with a slight bend in your elbows.",
                "Step forward into a staggered stance and bring your hands together in a wide arc.",
                "Slowly return to the starting position, feeling a stretch across your chest."
            ],
            commonMistakes: [
                "Bending the elbows too much, turning it into a press.",
                "Using too much weight and losing the controlled arc motion.",
                "Leaning too far forward, shifting tension to the shoulders."
            ]
        ),
        ExerciseLibraryItem(
            name: "Dips",
            description: "A compound bodyweight exercise targeting the chest and triceps using parallel bars.",
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders],
            equipment: .bodyweight,
            difficulty: .intermediate,
            instructions: [
                "Grip the parallel bars and lift yourself to a straight-arm position.",
                "Lean your torso slightly forward and lower until your upper arms are parallel to the floor.",
                "Push back up to full lockout without swinging your legs."
            ],
            commonMistakes: [
                "Staying too upright, shifting all the work to the triceps.",
                "Going too deep and straining the shoulder capsule.",
                "Swinging or kipping to complete reps."
            ]
        ),
        ExerciseLibraryItem(
            name: "Push-Up",
            description: "A fundamental bodyweight pressing movement for chest, shoulders, and triceps.",
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders, .core],
            equipment: .bodyweight,
            difficulty: .beginner,
            instructions: [
                "Start in a high plank with hands just outside shoulder-width and body in a straight line.",
                "Lower your chest to the floor by bending your elbows to about 90 degrees.",
                "Press back up to full extension while keeping your core braced."
            ],
            commonMistakes: [
                "Letting the hips sag, placing excessive stress on the lower back.",
                "Flaring the elbows straight out to the sides.",
                "Only performing partial reps instead of full range of motion."
            ]
        ),
        ExerciseLibraryItem(
            name: "Pec Deck",
            description: "A machine-based chest isolation exercise that mimics the fly movement pattern.",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders],
            equipment: .machine,
            difficulty: .beginner,
            instructions: [
                "Sit with your back flat against the pad and grip the handles at chest height.",
                "Squeeze your arms together in front of your chest in a controlled arc.",
                "Slowly return to the starting position until you feel a comfortable stretch."
            ],
            commonMistakes: [
                "Setting the arms too far back, overstretching the shoulder joint.",
                "Using momentum to slam the handles together.",
                "Shrugging the shoulders up instead of keeping them depressed."
            ]
        ),
        ExerciseLibraryItem(
            name: "Decline Bench Press",
            description: "A barbell press on a declined bench targeting the lower portion of the chest.",
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders],
            equipment: .barbell,
            difficulty: .intermediate,
            instructions: [
                "Secure your legs in the decline bench and lie back with a grip just outside shoulder-width.",
                "Unrack and lower the bar to your lower chest with controlled speed.",
                "Press the bar back to lockout, keeping your shoulder blades retracted."
            ],
            commonMistakes: [
                "Lowering the bar too high toward the neck instead of the lower chest.",
                "Using a grip that is too narrow, shifting emphasis to the triceps.",
                "Failing to secure legs properly, causing instability."
            ]
        ),
        ExerciseLibraryItem(
            name: "Landmine Press",
            description: "A unilateral pressing movement using a barbell anchored at one end.",
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .triceps, .core],
            equipment: .barbell,
            difficulty: .intermediate,
            instructions: [
                "Stand facing the barbell end in a staggered stance, holding it at shoulder height with one hand.",
                "Press the bar up and forward at an angle, extending your arm fully.",
                "Lower the bar back to the starting position under control."
            ],
            commonMistakes: [
                "Rotating the torso excessively instead of pressing through the chest.",
                "Locking the knees and losing a stable base.",
                "Pressing straight up instead of following the natural arc of the barbell."
            ]
        ),
    ]

    // MARK: - Back (8)

    private static let back: [ExerciseLibraryItem] = [
        ExerciseLibraryItem(
            name: "Conventional Deadlift",
            description: "A full posterior chain compound lift pulling a barbell from the floor to a standing position.",
            primaryMuscles: [.back],
            secondaryMuscles: [.hamstrings, .glutes, .forearms, .core],
            equipment: .barbell,
            difficulty: .advanced,
            instructions: [
                "Stand with feet hip-width apart, shins touching the bar, and grip just outside the knees.",
                "Drive through your feet, extending hips and knees simultaneously while keeping the bar close.",
                "Stand tall with hips fully locked out, then reverse the movement to lower the bar."
            ],
            commonMistakes: [
                "Rounding the lower back during the pull.",
                "Letting the bar drift away from the body.",
                "Jerking the bar off the floor instead of building tension first."
            ]
        ),
        ExerciseLibraryItem(
            name: "Barbell Row",
            description: "A compound pulling movement performed with a hinged torso to build mid-back thickness.",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .forearms, .core],
            equipment: .barbell,
            difficulty: .intermediate,
            instructions: [
                "Hinge forward at the hips to roughly 45 degrees, holding the bar with an overhand grip.",
                "Pull the bar to your lower ribcage, driving your elbows behind you.",
                "Lower the bar under control until your arms are fully extended."
            ],
            commonMistakes: [
                "Using excessive body English to heave the weight up.",
                "Standing too upright, reducing the range of motion.",
                "Pulling to the waist instead of the ribcage."
            ]
        ),
        ExerciseLibraryItem(
            name: "Pull-Up",
            description: "A bodyweight vertical pull building lat width and upper back strength.",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .forearms],
            equipment: .pullUpBar,
            difficulty: .intermediate,
            instructions: [
                "Hang from the bar with an overhand grip slightly wider than shoulder-width.",
                "Pull yourself up until your chin clears the bar, leading with your chest.",
                "Lower yourself under control to a full dead hang."
            ],
            commonMistakes: [
                "Kipping or swinging to generate momentum.",
                "Not reaching full extension at the bottom of each rep.",
                "Craning the neck forward to fake clearing the bar."
            ]
        ),
        ExerciseLibraryItem(
            name: "Lat Pulldown",
            description: "A cable machine pull replicating the pull-up pattern with adjustable resistance.",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .forearms],
            equipment: .cableMachine,
            difficulty: .beginner,
            instructions: [
                "Sit with thighs secured under the pads and grip the bar slightly wider than shoulder-width.",
                "Pull the bar down to your upper chest while squeezing your shoulder blades together.",
                "Return the bar overhead with a slow, controlled motion."
            ],
            commonMistakes: [
                "Leaning too far back, turning it into a row.",
                "Pulling the bar behind the neck, stressing the shoulders.",
                "Using the biceps to do most of the work instead of initiating with the lats."
            ]
        ),
        ExerciseLibraryItem(
            name: "Seated Cable Row",
            description: "A horizontal pull performed on a cable station to target the mid-back.",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .forearms],
            equipment: .cableMachine,
            difficulty: .beginner,
            instructions: [
                "Sit upright with feet on the platform and grab the handle with arms extended.",
                "Pull the handle to your lower ribcage, retracting your shoulder blades.",
                "Extend your arms back to the start without letting your torso round forward."
            ],
            commonMistakes: [
                "Rocking the torso back and forth excessively.",
                "Shrugging the shoulders up instead of pulling them back.",
                "Releasing the weight too fast on the eccentric."
            ]
        ),
        ExerciseLibraryItem(
            name: "Single-Arm Dumbbell Row",
            description: "A unilateral row using a bench for support to isolate each side of the back.",
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .forearms],
            equipment: .dumbbell,
            difficulty: .beginner,
            instructions: [
                "Place one knee and hand on a bench, holding a dumbbell in the other hand.",
                "Row the dumbbell to your hip, keeping your elbow close to your body.",
                "Lower the dumbbell until your arm is fully extended."
            ],
            commonMistakes: [
                "Rotating the torso to heave the weight up.",
                "Curling the wrist instead of driving with the elbow.",
                "Rounding the upper back instead of keeping a flat spine."
            ]
        ),
        ExerciseLibraryItem(
            name: "Face Pull",
            description: "A cable pull targeting the rear delts and upper back for shoulder health and posture.",
            primaryMuscles: [.back],
            secondaryMuscles: [.shoulders],
            equipment: .cableMachine,
            difficulty: .beginner,
            instructions: [
                "Set a cable with a rope attachment at upper-chest height.",
                "Pull the rope toward your face, flaring your elbows high and externally rotating at the end.",
                "Squeeze your rear delts and upper back, then slowly return to the start."
            ],
            commonMistakes: [
                "Using too much weight and turning it into a body-rock movement.",
                "Pulling too low toward the chest instead of face height.",
                "Not externally rotating at the end of the movement."
            ]
        ),
        ExerciseLibraryItem(
            name: "Romanian Deadlift",
            description: "A hip-hinge movement emphasizing the hamstrings and spinal erectors with a controlled eccentric.",
            primaryMuscles: [.back, .hamstrings],
            secondaryMuscles: [.glutes, .forearms],
            equipment: .barbell,
            difficulty: .intermediate,
            instructions: [
                "Stand with feet hip-width apart holding the barbell at hip height with a slight knee bend.",
                "Hinge at the hips, pushing them back, and lower the bar along your legs until you feel a deep hamstring stretch.",
                "Drive your hips forward to return to standing, squeezing the glutes at the top."
            ],
            commonMistakes: [
                "Bending the knees too much, turning it into a squat.",
                "Rounding the lower back instead of maintaining a neutral spine.",
                "Letting the bar drift away from the legs."
            ]
        ),
    ]

    // MARK: - Shoulders (5)

    private static let shoulders: [ExerciseLibraryItem] = [
        ExerciseLibraryItem(
            name: "Overhead Press",
            description: "A standing barbell press overhead building shoulder strength and stability.",
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.triceps, .core],
            equipment: .barbell,
            difficulty: .intermediate,
            instructions: [
                "Unrack the bar at collarbone height with a grip just outside shoulder-width.",
                "Press the bar overhead, moving your head through as the bar passes your forehead.",
                "Lock out with the bar directly over your midfoot, then lower under control."
            ],
            commonMistakes: [
                "Excessive lower back arch to compensate for weak shoulders.",
                "Pressing the bar forward instead of straight up.",
                "Not engaging the core, leading to instability."
            ]
        ),
        ExerciseLibraryItem(
            name: "Lateral Raise",
            description: "An isolation exercise lifting dumbbells out to the sides to build the medial deltoids.",
            primaryMuscles: [.shoulders],
            secondaryMuscles: [],
            equipment: .dumbbell,
            difficulty: .beginner,
            instructions: [
                "Stand holding light dumbbells at your sides with a slight elbow bend.",
                "Raise both arms out to the sides until they are parallel with the floor.",
                "Lower slowly back to the starting position without swinging."
            ],
            commonMistakes: [
                "Using momentum by swinging the torso.",
                "Raising the dumbbells above shoulder height, impinging the joint.",
                "Shrugging the traps instead of isolating the delts."
            ]
        ),
        ExerciseLibraryItem(
            name: "Arnold Press",
            description: "A dumbbell press with rotation that hits all three heads of the deltoid.",
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.triceps],
            equipment: .dumbbell,
            difficulty: .intermediate,
            instructions: [
                "Sit with dumbbells at shoulder height, palms facing you in a curl position.",
                "Rotate your palms outward as you press the dumbbells overhead.",
                "Reverse the rotation as you lower back to the starting position."
            ],
            commonMistakes: [
                "Rushing the rotation instead of making it smooth throughout the press.",
                "Flaring the elbows too wide at the bottom position.",
                "Arching the back excessively on the press."
            ]
        ),
        ExerciseLibraryItem(
            name: "Rear Delt Fly",
            description: "A bent-over dumbbell fly targeting the posterior deltoid.",
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.back],
            equipment: .dumbbell,
            difficulty: .beginner,
            instructions: [
                "Hinge at the hips with a flat back, holding dumbbells beneath your chest.",
                "Raise the dumbbells out to the sides, leading with your elbows.",
                "Lower under control, maintaining the hinged position throughout."
            ],
            commonMistakes: [
                "Lifting the torso up during each rep to use momentum.",
                "Using too much weight and turning it into a shrug.",
                "Bending the elbows excessively, shortening the lever arm."
            ]
        ),
        ExerciseLibraryItem(
            name: "Upright Row",
            description: "A barbell or dumbbell pull from the hips to chin height targeting shoulders and traps.",
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.biceps, .forearms],
            equipment: .barbell,
            difficulty: .intermediate,
            instructions: [
                "Hold the barbell with a shoulder-width grip at hip height.",
                "Pull the bar straight up along your body until your elbows are at shoulder height.",
                "Lower the bar back to the start in a controlled manner."
            ],
            commonMistakes: [
                "Using too narrow a grip, which increases shoulder impingement risk.",
                "Pulling the bar too high, stressing the rotator cuff.",
                "Leaning backward to use body momentum."
            ]
        ),
    ]

    // MARK: - Biceps (4)

    private static let biceps: [ExerciseLibraryItem] = [
        ExerciseLibraryItem(
            name: "Barbell Curl",
            description: "The standard barbell curl for building overall biceps mass.",
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .barbell,
            difficulty: .beginner,
            instructions: [
                "Stand with a shoulder-width underhand grip on the barbell, arms extended.",
                "Curl the bar up to shoulder height, keeping your elbows pinned to your sides.",
                "Lower the bar slowly to full extension."
            ],
            commonMistakes: [
                "Swinging the torso to generate momentum.",
                "Not lowering the bar all the way down each rep.",
                "Flaring the elbows forward during the curl."
            ]
        ),
        ExerciseLibraryItem(
            name: "Incline Dumbbell Curl",
            description: "A curl performed on an incline bench to increase the stretch on the long head of the biceps.",
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .dumbbell,
            difficulty: .intermediate,
            instructions: [
                "Sit back on a bench set to 45 degrees, letting your arms hang straight down.",
                "Curl both dumbbells up while keeping your upper arms stationary.",
                "Lower under control, feeling a deep stretch at the bottom."
            ],
            commonMistakes: [
                "Bringing the elbows forward to shorten the range of motion.",
                "Sitting too upright, reducing the stretch on the biceps.",
                "Using excessive weight and losing the controlled tempo."
            ]
        ),
        ExerciseLibraryItem(
            name: "Hammer Curl",
            description: "A neutral-grip dumbbell curl emphasizing the brachialis and brachioradialis.",
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .dumbbell,
            difficulty: .beginner,
            instructions: [
                "Stand holding dumbbells at your sides with palms facing each other.",
                "Curl both dumbbells up without rotating your wrists.",
                "Lower back to the starting position in a controlled motion."
            ],
            commonMistakes: [
                "Rotating the wrists during the curl instead of keeping a neutral grip.",
                "Swinging the body to lift heavier weights.",
                "Rushing through reps without controlling the negative."
            ]
        ),
        ExerciseLibraryItem(
            name: "Preacher Curl",
            description: "A curl performed on a preacher bench to eliminate momentum and isolate the biceps.",
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipment: .dumbbell,
            difficulty: .beginner,
            instructions: [
                "Sit at a preacher bench with the back of your upper arms flat on the pad.",
                "Curl the weight up to shoulder height, squeezing at the top.",
                "Lower slowly to near-full extension without hyperextending the elbow."
            ],
            commonMistakes: [
                "Lifting the elbows off the pad to cheat the weight up.",
                "Extending fully at the bottom, risking elbow hyperextension.",
                "Using a jerky motion instead of smooth, controlled reps."
            ]
        ),
    ]

    // MARK: - Triceps (4)

    private static let triceps: [ExerciseLibraryItem] = [
        ExerciseLibraryItem(
            name: "Close-Grip Bench Press",
            description: "A bench press variation with a narrow grip that shifts emphasis to the triceps.",
            primaryMuscles: [.triceps],
            secondaryMuscles: [.chest, .shoulders],
            equipment: .barbell,
            difficulty: .intermediate,
            instructions: [
                "Lie on a flat bench and grip the bar with hands about shoulder-width apart.",
                "Lower the bar to your lower chest, keeping your elbows tucked close to your body.",
                "Press back up to lockout, focusing on extending through the triceps."
            ],
            commonMistakes: [
                "Gripping too narrow, which strains the wrists.",
                "Flaring the elbows out wide, shifting work to the chest.",
                "Not locking out fully at the top."
            ]
        ),
        ExerciseLibraryItem(
            name: "Tricep Pushdown",
            description: "A cable isolation exercise for the triceps using a straight or rope attachment.",
            primaryMuscles: [.triceps],
            secondaryMuscles: [],
            equipment: .cableMachine,
            difficulty: .beginner,
            instructions: [
                "Stand facing the cable machine and grip the attachment with elbows at your sides.",
                "Push the handle down until your arms are fully extended.",
                "Return to the starting position without letting your elbows drift forward."
            ],
            commonMistakes: [
                "Letting the elbows flare forward, engaging the shoulders.",
                "Leaning over the weight instead of staying upright.",
                "Using excessive weight and losing isolation."
            ]
        ),
        ExerciseLibraryItem(
            name: "Overhead Tricep Extension",
            description: "A dumbbell extension performed overhead to stretch and load the long head of the triceps.",
            primaryMuscles: [.triceps],
            secondaryMuscles: [],
            equipment: .dumbbell,
            difficulty: .beginner,
            instructions: [
                "Hold a dumbbell overhead with both hands, arms fully extended.",
                "Lower the dumbbell behind your head by bending at the elbows.",
                "Extend your arms back to the starting position, squeezing the triceps at the top."
            ],
            commonMistakes: [
                "Flaring the elbows out wide during the movement.",
                "Arching the lower back instead of bracing the core.",
                "Using a partial range of motion."
            ]
        ),
        ExerciseLibraryItem(
            name: "Skull Crusher",
            description: "A lying triceps extension lowering the bar toward the forehead to target all three triceps heads.",
            primaryMuscles: [.triceps],
            secondaryMuscles: [],
            equipment: .barbell,
            difficulty: .intermediate,
            instructions: [
                "Lie on a flat bench holding a barbell with arms extended directly above your chest.",
                "Lower the bar toward your forehead by bending only at the elbows.",
                "Extend your arms back to the top, keeping your upper arms stationary."
            ],
            commonMistakes: [
                "Letting the upper arms drift backward, turning it into a pullover.",
                "Lowering the bar too fast, risking contact with the face.",
                "Flaring the elbows out instead of keeping them shoulder-width."
            ]
        ),
    ]

    // MARK: - Legs (10)

    private static let legs: [ExerciseLibraryItem] = [
        ExerciseLibraryItem(
            name: "Back Squat",
            description: "The king of leg exercises, loading the barbell across the upper back and squatting to depth.",
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings, .core],
            equipment: .barbell,
            difficulty: .intermediate,
            instructions: [
                "Position the bar across your upper traps, unrack, and step back with feet shoulder-width apart.",
                "Squat down by pushing hips back and bending knees until thighs are at least parallel.",
                "Drive through your whole foot to stand back up, keeping your chest tall."
            ],
            commonMistakes: [
                "Letting the knees cave inward during the ascent.",
                "Rounding the upper back under heavy loads.",
                "Rising on the toes instead of keeping the whole foot grounded."
            ]
        ),
        ExerciseLibraryItem(
            name: "Front Squat",
            description: "A barbell squat with the bar racked across the front deltoids, emphasizing the quads.",
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .core],
            equipment: .barbell,
            difficulty: .advanced,
            instructions: [
                "Rack the bar across your front deltoids with elbows high and fingertips under the bar.",
                "Squat down while keeping your torso as upright as possible.",
                "Stand back up by driving through your midfoot, maintaining high elbows throughout."
            ],
            commonMistakes: [
                "Dropping the elbows, causing the bar to roll forward.",
                "Leaning too far forward during the descent.",
                "Lacking the wrist and thoracic mobility for a proper rack position."
            ]
        ),
        ExerciseLibraryItem(
            name: "Leg Press",
            description: "A machine-based pressing movement for building quad and glute strength with back support.",
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings],
            equipment: .machine,
            difficulty: .beginner,
            instructions: [
                "Sit in the leg press with your back flat against the pad and feet shoulder-width on the platform.",
                "Lower the platform by bending your knees until they approach 90 degrees.",
                "Press the platform back up without fully locking out the knees."
            ],
            commonMistakes: [
                "Placing feet too low, overstressing the knees.",
                "Allowing the lower back to round off the pad at the bottom.",
                "Locking the knees completely at the top."
            ]
        ),
        ExerciseLibraryItem(
            name: "Leg Curl",
            description: "A machine isolation exercise targeting the hamstrings through knee flexion.",
            primaryMuscles: [.hamstrings],
            secondaryMuscles: [.calves],
            equipment: .machine,
            difficulty: .beginner,
            instructions: [
                "Lie face down on the leg curl machine with the pad resting on your lower calves.",
                "Curl your heels toward your glutes, squeezing the hamstrings at the top.",
                "Lower back to the start under control without letting the weight slam."
            ],
            commonMistakes: [
                "Lifting the hips off the pad to use momentum.",
                "Only performing partial reps at the top of the range.",
                "Using a fast, jerky motion instead of a smooth cadence."
            ]
        ),
        ExerciseLibraryItem(
            name: "Leg Extension",
            description: "A machine isolation exercise targeting the quadriceps through knee extension.",
            primaryMuscles: [.quads],
            secondaryMuscles: [],
            equipment: .machine,
            difficulty: .beginner,
            instructions: [
                "Sit in the machine with the pad on your lower shins and back against the seat.",
                "Extend your legs until they are straight, squeezing the quads at the top.",
                "Lower slowly back to the starting position."
            ],
            commonMistakes: [
                "Using excessive weight and swinging the legs up.",
                "Not achieving full extension at the top.",
                "Letting the weight drop quickly on the eccentric."
            ]
        ),
        ExerciseLibraryItem(
            name: "Bulgarian Split Squat",
            description: "A single-leg squat with the rear foot elevated, building unilateral leg strength and balance.",
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings, .core],
            equipment: .dumbbell,
            difficulty: .intermediate,
            instructions: [
                "Stand about two feet in front of a bench and place the top of your rear foot on it.",
                "Lower your back knee toward the floor while keeping your front shin nearly vertical.",
                "Push through your front foot to return to the starting position."
            ],
            commonMistakes: [
                "Standing too close to the bench, causing the front knee to travel too far forward.",
                "Leaning the torso excessively forward.",
                "Letting the front knee collapse inward."
            ]
        ),
        ExerciseLibraryItem(
            name: "Hip Thrust",
            description: "A glute-dominant movement performed with the upper back on a bench and a barbell across the hips.",
            primaryMuscles: [.glutes],
            secondaryMuscles: [.hamstrings, .core],
            equipment: .barbell,
            difficulty: .intermediate,
            instructions: [
                "Sit on the floor with your upper back against a bench and roll a barbell over your hips.",
                "Drive through your feet to raise your hips until your body forms a straight line from shoulders to knees.",
                "Squeeze your glutes hard at the top, then lower under control."
            ],
            commonMistakes: [
                "Hyperextending the lower back at the top instead of achieving a neutral spine.",
                "Placing feet too far from the body, shifting work to the hamstrings.",
                "Not pausing at the top and rushing through reps."
            ]
        ),
        ExerciseLibraryItem(
            name: "Calf Raise",
            description: "An isolation exercise for the calves performed standing on a raised surface.",
            primaryMuscles: [.calves],
            secondaryMuscles: [],
            equipment: .machine,
            difficulty: .beginner,
            instructions: [
                "Stand on the edge of a calf raise platform with the balls of your feet on the surface.",
                "Rise up onto your toes as high as possible, squeezing your calves.",
                "Lower your heels below the platform for a full stretch, then repeat."
            ],
            commonMistakes: [
                "Bouncing at the bottom instead of using a full range of motion.",
                "Bending the knees to use momentum.",
                "Not going through the full eccentric stretch."
            ]
        ),
        ExerciseLibraryItem(
            name: "Walking Lunge",
            description: "A dynamic unilateral leg exercise performed by stepping forward into alternating lunges.",
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings, .core],
            equipment: .dumbbell,
            difficulty: .intermediate,
            instructions: [
                "Hold a dumbbell in each hand and stand tall with feet together.",
                "Step forward into a lunge until both knees form 90-degree angles.",
                "Push off the front foot and step through into the next lunge."
            ],
            commonMistakes: [
                "Taking too short a step, causing the knee to go well past the toes.",
                "Leaning the torso forward instead of staying upright.",
                "Letting the back knee slam into the ground."
            ]
        ),
        ExerciseLibraryItem(
            name: "Sumo Deadlift",
            description: "A wide-stance deadlift variation that emphasizes the quads, adductors, and glutes.",
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings, .back, .forearms],
            equipment: .barbell,
            difficulty: .advanced,
            instructions: [
                "Stand with a wide stance and toes pointed outward, gripping the bar with a narrow grip between your knees.",
                "Drop your hips, push your knees out over your toes, and drive through the floor.",
                "Stand tall with hips locked out, then return the bar to the floor under control."
            ],
            commonMistakes: [
                "Letting the knees cave inward during the pull.",
                "Setting the hips too high, turning it into a conventional deadlift.",
                "Rounding the upper back instead of maintaining a proud chest."
            ]
        ),
    ]

    // MARK: - Core (5)

    private static let core: [ExerciseLibraryItem] = [
        ExerciseLibraryItem(
            name: "Plank",
            description: "An isometric core exercise holding a rigid position to build endurance and stability.",
            primaryMuscles: [.core],
            secondaryMuscles: [.shoulders, .glutes],
            equipment: .bodyweight,
            difficulty: .beginner,
            instructions: [
                "Place your forearms on the ground with elbows directly under your shoulders.",
                "Extend your legs back, balancing on your toes, and brace your core tight.",
                "Hold the position in a straight line from head to heels without sagging or piking."
            ],
            commonMistakes: [
                "Letting the hips sag toward the floor.",
                "Piking the hips too high, reducing core engagement.",
                "Holding the breath instead of breathing steadily."
            ]
        ),
        ExerciseLibraryItem(
            name: "Cable Crunch",
            description: "A weighted crunch using a cable machine to provide resistance through the full range of motion.",
            primaryMuscles: [.core],
            secondaryMuscles: [],
            equipment: .cableMachine,
            difficulty: .intermediate,
            instructions: [
                "Kneel below a high cable with a rope attachment held behind your head.",
                "Crunch downward by contracting your abs, bringing your elbows toward your knees.",
                "Return to the upright kneeling position under control."
            ],
            commonMistakes: [
                "Using the hip flexors to pull down instead of the abs.",
                "Sitting back onto the heels during the crunch.",
                "Moving the arms instead of keeping them locked in position."
            ]
        ),
        ExerciseLibraryItem(
            name: "Ab Wheel Rollout",
            description: "An anti-extension core exercise using an ab wheel to challenge stability under load.",
            primaryMuscles: [.core],
            secondaryMuscles: [.shoulders],
            equipment: .bodyweight,
            difficulty: .advanced,
            instructions: [
                "Kneel on the floor gripping the ab wheel with both hands directly under your shoulders.",
                "Roll the wheel forward, extending your body as far as you can without losing core tension.",
                "Pull the wheel back to the starting position by contracting your abs."
            ],
            commonMistakes: [
                "Collapsing the lower back at full extension.",
                "Bending at the hips on the way back instead of using the abs.",
                "Going too far too fast before building adequate core strength."
            ]
        ),
        ExerciseLibraryItem(
            name: "Hanging Leg Raise",
            description: "A hanging core exercise lifting the legs to target the lower abs and hip flexors.",
            primaryMuscles: [.core],
            secondaryMuscles: [.forearms],
            equipment: .pullUpBar,
            difficulty: .intermediate,
            instructions: [
                "Hang from a pull-up bar with an overhand grip and legs straight.",
                "Raise your legs until they are parallel to the floor or higher, using your abs to lift.",
                "Lower your legs slowly back to the dead hang position."
            ],
            commonMistakes: [
                "Swinging and using momentum instead of controlled movement.",
                "Only raising the knees partway instead of lifting straight legs.",
                "Losing grip and cutting sets short due to forearm fatigue."
            ]
        ),
        ExerciseLibraryItem(
            name: "Russian Twist",
            description: "A rotational core exercise performed seated with a weight to build oblique strength.",
            primaryMuscles: [.core],
            secondaryMuscles: [],
            equipment: .dumbbell,
            difficulty: .beginner,
            instructions: [
                "Sit on the floor with knees bent, lean back slightly, and hold a dumbbell with both hands.",
                "Rotate your torso to one side, bringing the weight beside your hip.",
                "Rotate to the opposite side in a controlled manner, keeping your feet off the floor for added challenge."
            ],
            commonMistakes: [
                "Moving only the arms instead of rotating the entire torso.",
                "Rounding the back instead of maintaining a tall spine.",
                "Using too heavy a weight and sacrificing rotation range."
            ]
        ),
    ]

    // MARK: - Full Body (6)

    private static let fullBody: [ExerciseLibraryItem] = [
        ExerciseLibraryItem(
            name: "Power Clean",
            description: "An explosive Olympic lift pulling the barbell from the floor to the front rack position.",
            primaryMuscles: [.fullBody],
            secondaryMuscles: [.quads, .glutes, .hamstrings, .shoulders, .back],
            equipment: .barbell,
            difficulty: .advanced,
            instructions: [
                "Set up like a deadlift with a shoulder-width grip, then explosively extend the hips and pull the bar upward.",
                "As the bar reaches chest height, drop under it and catch it in a front rack position.",
                "Stand up fully, then lower the bar back to the floor."
            ],
            commonMistakes: [
                "Pulling with the arms too early instead of using hip drive.",
                "Not getting the elbows around fast enough for the catch.",
                "Landing with feet too wide in the catch position."
            ]
        ),
        ExerciseLibraryItem(
            name: "Turkish Get-Up",
            description: "A multi-step full-body movement rising from the floor to standing while holding a weight overhead.",
            primaryMuscles: [.fullBody],
            secondaryMuscles: [.shoulders, .core, .glutes],
            equipment: .kettlebell,
            difficulty: .advanced,
            instructions: [
                "Lie on your back holding a kettlebell locked out overhead with one arm.",
                "Perform the get-up sequence: roll to elbow, post on hand, bridge hips, sweep leg, kneel, then stand.",
                "Reverse each step to return to the starting position on the floor."
            ],
            commonMistakes: [
                "Losing visual contact with the kettlebell during transitions.",
                "Rushing through the individual steps instead of being deliberate.",
                "Letting the wrist bend back instead of keeping it neutral."
            ]
        ),
        ExerciseLibraryItem(
            name: "Kettlebell Swing",
            description: "A ballistic hip-hinge movement swinging a kettlebell to build explosive power and conditioning.",
            primaryMuscles: [.fullBody],
            secondaryMuscles: [.glutes, .hamstrings, .core, .shoulders],
            equipment: .kettlebell,
            difficulty: .intermediate,
            instructions: [
                "Stand with feet wider than shoulder-width, hinge at the hips, and grip the kettlebell with both hands.",
                "Hike the kettlebell between your legs, then explosively drive your hips forward to swing it to chest height.",
                "Let the kettlebell fall back between your legs and repeat without pausing."
            ],
            commonMistakes: [
                "Squatting the movement instead of hinging at the hips.",
                "Using the arms to lift the bell instead of driving with the hips.",
                "Rounding the lower back at the bottom of the swing."
            ]
        ),
        ExerciseLibraryItem(
            name: "Thruster",
            description: "A front squat into an overhead press in one fluid motion for total-body conditioning.",
            primaryMuscles: [.fullBody],
            secondaryMuscles: [.quads, .glutes, .shoulders, .triceps, .core],
            equipment: .barbell,
            difficulty: .intermediate,
            instructions: [
                "Hold the barbell in a front rack position and descend into a full front squat.",
                "Explosively stand up and use the momentum to press the bar overhead.",
                "Lower the bar back to the front rack as you descend into the next squat."
            ],
            commonMistakes: [
                "Pausing between the squat and the press instead of making it one fluid motion.",
                "Pressing before the legs are fully extended, losing power.",
                "Letting the elbows drop during the front rack position."
            ]
        ),
        ExerciseLibraryItem(
            name: "Burpee",
            description: "A high-intensity bodyweight exercise combining a squat thrust, push-up, and jump.",
            primaryMuscles: [.fullBody],
            secondaryMuscles: [.chest, .quads, .core, .shoulders],
            equipment: .bodyweight,
            difficulty: .intermediate,
            instructions: [
                "From standing, squat down and place your hands on the floor, then kick your feet back into a push-up position.",
                "Perform a push-up, then jump your feet back toward your hands.",
                "Explode upward into a jump with your arms overhead."
            ],
            commonMistakes: [
                "Skipping the push-up and doing a half rep.",
                "Landing with stiff legs on the jump, stressing the joints.",
                "Losing core tension when kicking the feet back."
            ]
        ),
        ExerciseLibraryItem(
            name: "Bear Crawl",
            description: "A locomotion exercise moving on all fours to develop coordination, core stability, and conditioning.",
            primaryMuscles: [.fullBody],
            secondaryMuscles: [.core, .shoulders, .quads],
            equipment: .bodyweight,
            difficulty: .beginner,
            instructions: [
                "Start on all fours with your knees hovering an inch off the ground.",
                "Move forward by simultaneously advancing the opposite hand and foot.",
                "Keep your back flat and hips low as you crawl for the prescribed distance."
            ],
            commonMistakes: [
                "Raising the hips too high, reducing core engagement.",
                "Moving the same-side hand and foot together instead of contralateral pairs.",
                "Moving too fast and losing the controlled, stable position."
            ]
        ),
    ]

    // MARK: - Filter & Search Methods

    static func exercises(for muscleGroup: MuscleGroup) -> [ExerciseLibraryItem] {
        allExercises.filter { $0.primaryMuscles.contains(muscleGroup) }
    }

    static func exercises(for equipment: ExerciseEquipment) -> [ExerciseLibraryItem] {
        allExercises.filter { $0.equipment == equipment }
    }

    static func search(query: String) -> [ExerciseLibraryItem] {
        let lowered = query.lowercased()
        return allExercises.filter { exercise in
            exercise.name.lowercased().contains(lowered)
                || exercise.description.lowercased().contains(lowered)
                || exercise.primaryMuscles.contains(where: { $0.rawValue.lowercased().contains(lowered) })
                || exercise.secondaryMuscles.contains(where: { $0.rawValue.lowercased().contains(lowered) })
                || exercise.equipment.rawValue.lowercased().contains(lowered)
        }
    }
}
