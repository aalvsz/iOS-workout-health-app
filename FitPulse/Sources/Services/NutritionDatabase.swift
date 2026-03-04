import Foundation

// MARK: - Nutrition Entry

struct NutritionEntry {
    let name: String
    let aliases: [String]
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let defaultServingG: Double
}

// MARK: - Nutrition Database

struct NutritionDatabase {
    static let shared = NutritionDatabase()

    // MARK: - Food Database (~200 common foods, USDA values)

    let entries: [NutritionEntry] = [
        // --- Proteins ---
        NutritionEntry(name: "Chicken Breast", aliases: ["chicken breast", "chicken", "grilled chicken", "pollo", "pechuga", "poulet", "blanc de poulet"], caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6, defaultServingG: 150),
        NutritionEntry(name: "Beef Steak", aliases: ["beef steak", "steak", "beef", "sirloin", "ribeye", "filet", "filete", "bistec", "boeuf", "bifteck", "entrecôte"], caloriesPer100g: 271, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 18, defaultServingG: 200),
        NutritionEntry(name: "Veal", aliases: ["veal", "ternera", "veau", "filete de ternera", "escalope de veau"], caloriesPer100g: 172, proteinPer100g: 24, carbsPer100g: 0, fatPer100g: 8, defaultServingG: 150),
        NutritionEntry(name: "Ground Beef (lean)", aliases: ["ground beef", "minced beef", "mince", "carne picada", "viande hachée", "boeuf haché", "steak haché", "steak hache", "hache", "hamburger meat"], caloriesPer100g: 250, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 15, defaultServingG: 150),
        NutritionEntry(name: "Lamb", aliases: ["lamb", "lamb chop", "cordero", "agneau", "côtelette d'agneau"], caloriesPer100g: 294, proteinPer100g: 25, carbsPer100g: 0, fatPer100g: 21, defaultServingG: 150),
        NutritionEntry(name: "Salmon", aliases: ["salmon", "salmon fillet", "smoked salmon", "salmón", "saumon", "saumon fumé"], caloriesPer100g: 208, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 13, defaultServingG: 150),
        NutritionEntry(name: "Tuna", aliases: ["tuna", "tuna steak", "canned tuna", "tuna can", "atún", "thon"], caloriesPer100g: 130, proteinPer100g: 29, carbsPer100g: 0, fatPer100g: 1, defaultServingG: 100),
        NutritionEntry(name: "White Fish", aliases: ["fish", "white fish", "cod", "hake", "tilapia", "sea bass", "merluza", "bacalao", "pescado", "poisson", "cabillaud", "colin", "dorada", "lubina"], caloriesPer100g: 105, proteinPer100g: 23, carbsPer100g: 0, fatPer100g: 1, defaultServingG: 200),
        NutritionEntry(name: "Sardines", aliases: ["sardines", "sardine", "sardinas", "sardines en boîte"], caloriesPer100g: 208, proteinPer100g: 25, carbsPer100g: 0, fatPer100g: 11, defaultServingG: 100),
        NutritionEntry(name: "Shrimp", aliases: ["shrimp", "prawns", "gambas", "crevettes", "langostinos"], caloriesPer100g: 99, proteinPer100g: 24, carbsPer100g: 0.2, fatPer100g: 0.3, defaultServingG: 100),
        NutritionEntry(name: "Turkey Breast", aliases: ["turkey breast", "turkey", "pavo", "dinde"], caloriesPer100g: 135, proteinPer100g: 30, carbsPer100g: 0, fatPer100g: 1, defaultServingG: 150),
        NutritionEntry(name: "Pork Loin", aliases: ["pork loin", "pork", "pork chop", "lomo", "cerdo", "porc", "côte de porc", "longe de porc", "chuleta"], caloriesPer100g: 196, proteinPer100g: 27, carbsPer100g: 0, fatPer100g: 9, defaultServingG: 150),
        NutritionEntry(name: "Duck", aliases: ["duck", "pato", "canard"], caloriesPer100g: 337, proteinPer100g: 19, carbsPer100g: 0, fatPer100g: 28, defaultServingG: 150),
        NutritionEntry(name: "Egg", aliases: ["egg", "eggs", "huevo", "huevos", "fried egg", "boiled egg", "scrambled egg", "scrambled eggs", "oeuf", "oeufs", "omelette", "omelet", "tortilla francesa", "omelette française", "revuelto"], caloriesPer100g: 155, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 11, defaultServingG: 60),
        NutritionEntry(name: "Egg White", aliases: ["egg white", "egg whites", "clara de huevo", "blanc d'oeuf"], caloriesPer100g: 52, proteinPer100g: 11, carbsPer100g: 0.7, fatPer100g: 0.2, defaultServingG: 33),
        NutritionEntry(name: "Tofu", aliases: ["tofu", "firm tofu"], caloriesPer100g: 144, proteinPer100g: 17, carbsPer100g: 3, fatPer100g: 8, defaultServingG: 150),
        NutritionEntry(name: "Tempeh", aliases: ["tempeh"], caloriesPer100g: 192, proteinPer100g: 20, carbsPer100g: 8, fatPer100g: 11, defaultServingG: 100),

        // --- Dairy ---
        NutritionEntry(name: "Whole Milk", aliases: ["milk", "whole milk", "leche", "lait", "lait entier"], caloriesPer100g: 61, proteinPer100g: 3.2, carbsPer100g: 4.8, fatPer100g: 3.3, defaultServingG: 240),
        NutritionEntry(name: "Skim Milk", aliases: ["skim milk", "skimmed milk", "leche desnatada", "lait écrémé"], caloriesPer100g: 34, proteinPer100g: 3.4, carbsPer100g: 5, fatPer100g: 0.1, defaultServingG: 240),
        NutritionEntry(name: "Greek Yogurt", aliases: ["greek yogurt", "yogurt", "yoghurt", "yogur", "yaourt", "yaourt grec", "yogourt"], caloriesPer100g: 59, proteinPer100g: 10, carbsPer100g: 3.6, fatPer100g: 0.4, defaultServingG: 170),
        NutritionEntry(name: "Cottage Cheese", aliases: ["cottage cheese", "requesón", "fromage blanc"], caloriesPer100g: 98, proteinPer100g: 11, carbsPer100g: 3.4, fatPer100g: 4.3, defaultServingG: 150),
        NutritionEntry(name: "Cheddar Cheese", aliases: ["cheddar", "cheese", "queso", "fromage"], caloriesPer100g: 403, proteinPer100g: 25, carbsPer100g: 1.3, fatPer100g: 33, defaultServingG: 30),
        NutritionEntry(name: "Mozzarella", aliases: ["mozzarella"], caloriesPer100g: 280, proteinPer100g: 28, carbsPer100g: 3.1, fatPer100g: 17, defaultServingG: 30),
        NutritionEntry(name: "Parmesan", aliases: ["parmesan", "parmesano", "parmersano", "parmigiano", "parmeggiano", "queso parmesano"], caloriesPer100g: 431, proteinPer100g: 38, carbsPer100g: 4, fatPer100g: 29, defaultServingG: 10),
        NutritionEntry(name: "Cream", aliases: ["cream", "heavy cream", "nata", "crème", "crème fraîche"], caloriesPer100g: 340, proteinPer100g: 2, carbsPer100g: 3, fatPer100g: 36, defaultServingG: 30),
        NutritionEntry(name: "Whey Protein", aliases: ["whey protein", "protein shake", "protein powder", "whey", "batido de proteina", "proteina", "protéine en poudre", "shake protéiné"], caloriesPer100g: 400, proteinPer100g: 80, carbsPer100g: 10, fatPer100g: 5, defaultServingG: 30),
        NutritionEntry(name: "Cream Cheese", aliases: ["cream cheese", "queso crema", "philadelphia", "fromage frais"], caloriesPer100g: 342, proteinPer100g: 6, carbsPer100g: 4, fatPer100g: 34, defaultServingG: 30),

        // --- Carbs / Grains ---
        NutritionEntry(name: "White Rice (cooked)", aliases: ["rice", "white rice", "arroz", "arroz blanco", "riz", "riz blanc"], caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28, fatPer100g: 0.3, defaultServingG: 185),
        NutritionEntry(name: "Brown Rice (cooked)", aliases: ["brown rice", "arroz integral", "riz complet", "riz brun"], caloriesPer100g: 123, proteinPer100g: 2.6, carbsPer100g: 26, fatPer100g: 1, defaultServingG: 185),
        NutritionEntry(name: "Pasta (cooked)", aliases: ["pasta", "spaghetti", "macaroni", "penne", "noodles", "fideos", "pâtes", "fusilli", "rigatoni", "tagliatelle", "fettuccine"], caloriesPer100g: 131, proteinPer100g: 5, carbsPer100g: 25, fatPer100g: 1.1, defaultServingG: 200),
        NutritionEntry(name: "Oats", aliases: ["oats", "oatmeal", "porridge", "avena", "flocons d'avoine", "gachas"], caloriesPer100g: 389, proteinPer100g: 17, carbsPer100g: 66, fatPer100g: 7, defaultServingG: 50),
        NutritionEntry(name: "Bread", aliases: ["bread", "toast", "pan", "tostada", "whole wheat bread", "pain", "tartine", "pan de molde"], caloriesPer100g: 265, proteinPer100g: 9, carbsPer100g: 49, fatPer100g: 3.2, defaultServingG: 30),
        NutritionEntry(name: "Baguette", aliases: ["baguette", "french bread", "barra de pan"], caloriesPer100g: 274, proteinPer100g: 10, carbsPer100g: 52, fatPer100g: 2.4, defaultServingG: 60),
        NutritionEntry(name: "Tortilla (wheat)", aliases: ["tortilla", "wrap", "tortilla wrap"], caloriesPer100g: 312, proteinPer100g: 8.3, carbsPer100g: 52, fatPer100g: 8, defaultServingG: 40),
        NutritionEntry(name: "Croissant", aliases: ["croissant", "cruasán"], caloriesPer100g: 406, proteinPer100g: 8, carbsPer100g: 46, fatPer100g: 21, defaultServingG: 60),
        NutritionEntry(name: "Bagel", aliases: ["bagel"], caloriesPer100g: 250, proteinPer100g: 10, carbsPer100g: 49, fatPer100g: 1, defaultServingG: 100),
        NutritionEntry(name: "Sweet Potato", aliases: ["sweet potato", "boniato", "batata", "patate douce"], caloriesPer100g: 86, proteinPer100g: 1.6, carbsPer100g: 20, fatPer100g: 0.1, defaultServingG: 200),
        NutritionEntry(name: "Potato", aliases: ["potato", "potatoes", "patata", "patatas", "baked potato", "baked potatoes", "pomme de terre", "pommes de terre"], caloriesPer100g: 77, proteinPer100g: 2, carbsPer100g: 17, fatPer100g: 0.1, defaultServingG: 200),
        NutritionEntry(name: "Quinoa (cooked)", aliases: ["quinoa"], caloriesPer100g: 120, proteinPer100g: 4.4, carbsPer100g: 21, fatPer100g: 1.9, defaultServingG: 185),
        NutritionEntry(name: "Couscous (cooked)", aliases: ["couscous", "cuscús"], caloriesPer100g: 112, proteinPer100g: 3.8, carbsPer100g: 23, fatPer100g: 0.2, defaultServingG: 185),
        NutritionEntry(name: "Cornflakes", aliases: ["cornflakes", "cereal", "cereales", "céréales"], caloriesPer100g: 357, proteinPer100g: 8, carbsPer100g: 84, fatPer100g: 0.8, defaultServingG: 30),
        NutritionEntry(name: "Pancake", aliases: ["pancake", "pancakes", "tortita", "crêpe"], caloriesPer100g: 227, proteinPer100g: 6, carbsPer100g: 28, fatPer100g: 10, defaultServingG: 75),
        NutritionEntry(name: "Waffle", aliases: ["waffle", "waffles", "gofre"], caloriesPer100g: 291, proteinPer100g: 8, carbsPer100g: 33, fatPer100g: 14, defaultServingG: 75),
        NutritionEntry(name: "French Toast", aliases: ["french toast", "torrijas", "pain perdu"], caloriesPer100g: 229, proteinPer100g: 8, carbsPer100g: 26, fatPer100g: 10, defaultServingG: 60),

        // --- Fats / Nuts / Seeds ---
        NutritionEntry(name: "Olive Oil", aliases: ["olive oil", "aceite de oliva", "oil", "aceite", "aceita de oliva", "huile d'olive", "huile"], caloriesPer100g: 884, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100, defaultServingG: 14),
        NutritionEntry(name: "Butter", aliases: ["butter", "mantequilla", "beurre"], caloriesPer100g: 717, proteinPer100g: 0.9, carbsPer100g: 0.1, fatPer100g: 81, defaultServingG: 14),
        NutritionEntry(name: "Coconut Oil", aliases: ["coconut oil", "aceite de coco", "huile de coco"], caloriesPer100g: 862, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100, defaultServingG: 14),
        NutritionEntry(name: "Peanut Butter", aliases: ["peanut butter", "pb", "mantequilla de mani", "crema de cacahuete", "beurre de cacahuète"], caloriesPer100g: 588, proteinPer100g: 25, carbsPer100g: 20, fatPer100g: 50, defaultServingG: 32),
        NutritionEntry(name: "Almonds", aliases: ["almonds", "almond", "almendras", "amandes"], caloriesPer100g: 579, proteinPer100g: 21, carbsPer100g: 22, fatPer100g: 50, defaultServingG: 30),
        NutritionEntry(name: "Walnuts", aliases: ["walnuts", "walnut", "nueces", "noix"], caloriesPer100g: 654, proteinPer100g: 15, carbsPer100g: 14, fatPer100g: 65, defaultServingG: 30),
        NutritionEntry(name: "Cashews", aliases: ["cashews", "cashew", "anacardos", "cajou", "noix de cajou"], caloriesPer100g: 553, proteinPer100g: 18, carbsPer100g: 30, fatPer100g: 44, defaultServingG: 30),
        NutritionEntry(name: "Pistachios", aliases: ["pistachios", "pistachio", "pistachos", "pistaches"], caloriesPer100g: 560, proteinPer100g: 20, carbsPer100g: 28, fatPer100g: 45, defaultServingG: 30),
        NutritionEntry(name: "Chia Seeds", aliases: ["chia seeds", "chia", "semillas de chia", "graines de chia"], caloriesPer100g: 486, proteinPer100g: 17, carbsPer100g: 42, fatPer100g: 31, defaultServingG: 15),
        NutritionEntry(name: "Flaxseeds", aliases: ["flaxseeds", "flaxseed", "linaza", "graines de lin"], caloriesPer100g: 534, proteinPer100g: 18, carbsPer100g: 29, fatPer100g: 42, defaultServingG: 15),
        NutritionEntry(name: "Avocado", aliases: ["avocado", "aguacate", "avocat"], caloriesPer100g: 160, proteinPer100g: 2, carbsPer100g: 9, fatPer100g: 15, defaultServingG: 150),

        // --- Fruits ---
        NutritionEntry(name: "Banana", aliases: ["banana", "platano", "plátano", "banane"], caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23, fatPer100g: 0.3, defaultServingG: 120),
        NutritionEntry(name: "Apple", aliases: ["apple", "manzana", "pomme"], caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2, defaultServingG: 180),
        NutritionEntry(name: "Orange", aliases: ["orange", "naranja"], caloriesPer100g: 47, proteinPer100g: 0.9, carbsPer100g: 12, fatPer100g: 0.1, defaultServingG: 150),
        NutritionEntry(name: "Strawberries", aliases: ["strawberry", "strawberries", "fresas", "fresa", "fraise", "fraises"], caloriesPer100g: 32, proteinPer100g: 0.7, carbsPer100g: 8, fatPer100g: 0.3, defaultServingG: 150),
        NutritionEntry(name: "Blueberries", aliases: ["blueberry", "blueberries", "arandanos", "arándanos", "myrtille", "myrtilles"], caloriesPer100g: 57, proteinPer100g: 0.7, carbsPer100g: 14, fatPer100g: 0.3, defaultServingG: 100),
        NutritionEntry(name: "Mixed Berries", aliases: ["berries", "mixed berries", "frutas del bosque", "fruits rouges"], caloriesPer100g: 45, proteinPer100g: 0.7, carbsPer100g: 11, fatPer100g: 0.3, defaultServingG: 100),
        NutritionEntry(name: "Mango", aliases: ["mango", "mangue"], caloriesPer100g: 60, proteinPer100g: 0.8, carbsPer100g: 15, fatPer100g: 0.4, defaultServingG: 150),
        NutritionEntry(name: "Grapes", aliases: ["grapes", "grape", "uvas", "raisin", "raisins"], caloriesPer100g: 69, proteinPer100g: 0.7, carbsPer100g: 18, fatPer100g: 0.2, defaultServingG: 100),
        NutritionEntry(name: "Watermelon", aliases: ["watermelon", "sandía", "pastèque"], caloriesPer100g: 30, proteinPer100g: 0.6, carbsPer100g: 8, fatPer100g: 0.2, defaultServingG: 200),
        NutritionEntry(name: "Pineapple", aliases: ["pineapple", "piña", "ananas"], caloriesPer100g: 50, proteinPer100g: 0.5, carbsPer100g: 13, fatPer100g: 0.1, defaultServingG: 150),
        NutritionEntry(name: "Peach", aliases: ["peach", "melocotón", "pêche"], caloriesPer100g: 39, proteinPer100g: 0.9, carbsPer100g: 10, fatPer100g: 0.3, defaultServingG: 150),
        NutritionEntry(name: "Pear", aliases: ["pear", "pera", "poire"], caloriesPer100g: 57, proteinPer100g: 0.4, carbsPer100g: 15, fatPer100g: 0.1, defaultServingG: 180),
        NutritionEntry(name: "Kiwi", aliases: ["kiwi"], caloriesPer100g: 61, proteinPer100g: 1.1, carbsPer100g: 15, fatPer100g: 0.5, defaultServingG: 75),
        NutritionEntry(name: "Dried Fruit", aliases: ["dried fruit", "raisins", "dates", "frutos secos", "fruits secs", "pasas", "dátiles", "dattes"], caloriesPer100g: 299, proteinPer100g: 3, carbsPer100g: 79, fatPer100g: 0.5, defaultServingG: 30),

        // --- Vegetables ---
        NutritionEntry(name: "Broccoli", aliases: ["broccoli", "brocoli", "brécol"], caloriesPer100g: 34, proteinPer100g: 2.8, carbsPer100g: 7, fatPer100g: 0.4, defaultServingG: 150),
        NutritionEntry(name: "Spinach", aliases: ["spinach", "espinacas", "espinaca", "épinards", "épinard"], caloriesPer100g: 23, proteinPer100g: 2.9, carbsPer100g: 3.6, fatPer100g: 0.4, defaultServingG: 100),
        NutritionEntry(name: "Tomato", aliases: ["tomato", "tomatoes", "tomate", "tomates"], caloriesPer100g: 18, proteinPer100g: 0.9, carbsPer100g: 3.9, fatPer100g: 0.2, defaultServingG: 150),
        NutritionEntry(name: "Tomato Sauce", aliases: ["tomato sauce", "marinara", "salsa de tomate", "sauce tomate"], caloriesPer100g: 29, proteinPer100g: 1.3, carbsPer100g: 6, fatPer100g: 0.2, defaultServingG: 125),
        NutritionEntry(name: "Onion", aliases: ["onion", "onions", "cebolla", "oignon", "oignons"], caloriesPer100g: 40, proteinPer100g: 1.1, carbsPer100g: 9.3, fatPer100g: 0.1, defaultServingG: 100),
        NutritionEntry(name: "Bell Pepper", aliases: ["bell pepper", "pepper", "pimiento", "peppers", "poivron", "poivrons"], caloriesPer100g: 31, proteinPer100g: 1, carbsPer100g: 6, fatPer100g: 0.3, defaultServingG: 120),
        NutritionEntry(name: "Lettuce", aliases: ["lettuce", "salad", "lechuga", "ensalada", "laitue", "salade", "salade verte", "salade vert", "ensalada mixta"], caloriesPer100g: 15, proteinPer100g: 1.4, carbsPer100g: 2.9, fatPer100g: 0.2, defaultServingG: 100),
        NutritionEntry(name: "Cucumber", aliases: ["cucumber", "pepino", "concombre"], caloriesPer100g: 16, proteinPer100g: 0.7, carbsPer100g: 3.6, fatPer100g: 0.1, defaultServingG: 100),
        NutritionEntry(name: "Carrot", aliases: ["carrot", "carrots", "zanahoria", "zanahorias", "carotte", "carottes"], caloriesPer100g: 41, proteinPer100g: 0.9, carbsPer100g: 10, fatPer100g: 0.2, defaultServingG: 80),
        NutritionEntry(name: "Green Beans", aliases: ["green beans", "judias verdes", "ejotes", "haricots verts"], caloriesPer100g: 31, proteinPer100g: 1.8, carbsPer100g: 7, fatPer100g: 0.1, defaultServingG: 100),
        NutritionEntry(name: "Mushrooms", aliases: ["mushroom", "mushrooms", "champiñones", "setas", "champignon", "champignons"], caloriesPer100g: 22, proteinPer100g: 3.1, carbsPer100g: 3.3, fatPer100g: 0.3, defaultServingG: 100),
        NutritionEntry(name: "Asparagus", aliases: ["asparagus", "espárragos", "asperges"], caloriesPer100g: 20, proteinPer100g: 2.2, carbsPer100g: 3.9, fatPer100g: 0.1, defaultServingG: 100),
        NutritionEntry(name: "Corn", aliases: ["corn", "maiz", "maíz", "sweet corn", "maïs"], caloriesPer100g: 86, proteinPer100g: 3.3, carbsPer100g: 19, fatPer100g: 1.4, defaultServingG: 100),
        NutritionEntry(name: "Zucchini", aliases: ["zucchini", "courgette", "calabacín"], caloriesPer100g: 17, proteinPer100g: 1.2, carbsPer100g: 3.1, fatPer100g: 0.3, defaultServingG: 150),
        NutritionEntry(name: "Eggplant", aliases: ["eggplant", "aubergine", "berenjena"], caloriesPer100g: 25, proteinPer100g: 1, carbsPer100g: 6, fatPer100g: 0.2, defaultServingG: 150),
        NutritionEntry(name: "Cabbage", aliases: ["cabbage", "col", "repollo", "chou"], caloriesPer100g: 25, proteinPer100g: 1.3, carbsPer100g: 6, fatPer100g: 0.1, defaultServingG: 100),

        // --- Legumes ---
        NutritionEntry(name: "Lentils (cooked)", aliases: ["lentils", "lentejas", "lentilles"], caloriesPer100g: 116, proteinPer100g: 9, carbsPer100g: 20, fatPer100g: 0.4, defaultServingG: 200),
        NutritionEntry(name: "Chickpeas (cooked)", aliases: ["chickpeas", "garbanzos", "hummus base", "pois chiches"], caloriesPer100g: 164, proteinPer100g: 8.9, carbsPer100g: 27, fatPer100g: 2.6, defaultServingG: 150),
        NutritionEntry(name: "Black Beans (cooked)", aliases: ["black beans", "frijoles negros", "beans", "haricots noirs", "frijoles", "alubias"], caloriesPer100g: 132, proteinPer100g: 8.9, carbsPer100g: 24, fatPer100g: 0.5, defaultServingG: 150),
        NutritionEntry(name: "Edamame", aliases: ["edamame", "soy beans", "soja"], caloriesPer100g: 121, proteinPer100g: 12, carbsPer100g: 9, fatPer100g: 5, defaultServingG: 100),

        // --- Drinks ---
        NutritionEntry(name: "Coffee (black)", aliases: ["coffee", "black coffee", "café", "cafe", "espresso", "café solo", "café negro"], caloriesPer100g: 2, proteinPer100g: 0.3, carbsPer100g: 0, fatPer100g: 0, defaultServingG: 240),
        NutritionEntry(name: "Café con Leche", aliases: ["cafe con leche", "café con leche", "latte", "cafe latte", "café latte", "cappuccino", "cortado", "flat white", "café au lait"], caloriesPer100g: 56, proteinPer100g: 3, carbsPer100g: 5, fatPer100g: 2.4, defaultServingG: 240),
        NutritionEntry(name: "Tea", aliases: ["tea", "green tea", "black tea", "té", "thé", "infusion", "infusión"], caloriesPer100g: 1, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 0, defaultServingG: 240),
        NutritionEntry(name: "Hot Chocolate", aliases: ["hot chocolate", "chocolate caliente", "chocolat chaud", "cacao", "cocoa"], caloriesPer100g: 77, proteinPer100g: 3.5, carbsPer100g: 10, fatPer100g: 2.9, defaultServingG: 240),
        NutritionEntry(name: "Orange Juice", aliases: ["orange juice", "oj", "zumo de naranja", "juice", "jus d'orange", "jus", "zumo"], caloriesPer100g: 45, proteinPer100g: 0.7, carbsPer100g: 10, fatPer100g: 0.2, defaultServingG: 250),
        NutritionEntry(name: "Coca-Cola", aliases: ["coca cola", "coke", "cola", "soda", "refresco", "pepsi", "sprite", "fanta"], caloriesPer100g: 42, proteinPer100g: 0, carbsPer100g: 11, fatPer100g: 0, defaultServingG: 330),
        NutritionEntry(name: "Beer", aliases: ["beer", "cerveza", "bière", "lager", "ale", "ipa"], caloriesPer100g: 43, proteinPer100g: 0.5, carbsPer100g: 3.6, fatPer100g: 0, defaultServingG: 330),
        NutritionEntry(name: "Red Wine", aliases: ["red wine", "wine", "vino", "vino tinto", "vin", "vin rouge"], caloriesPer100g: 85, proteinPer100g: 0.1, carbsPer100g: 2.6, fatPer100g: 0, defaultServingG: 150),
        NutritionEntry(name: "White Wine", aliases: ["white wine", "vino blanco", "vin blanc"], caloriesPer100g: 82, proteinPer100g: 0.1, carbsPer100g: 2.6, fatPer100g: 0, defaultServingG: 150),
        NutritionEntry(name: "Milkshake", aliases: ["milkshake", "smoothie", "batido"], caloriesPer100g: 112, proteinPer100g: 3.4, carbsPer100g: 18, fatPer100g: 3.2, defaultServingG: 400),

        // --- Prepared Meals ---
        NutritionEntry(name: "Pizza", aliases: ["pizza", "pizza slice", "pizza margherita"], caloriesPer100g: 266, proteinPer100g: 11, carbsPer100g: 33, fatPer100g: 10, defaultServingG: 107),
        NutritionEntry(name: "Hamburger", aliases: ["hamburger", "burger", "cheeseburger", "big mac", "hamburgesa"], caloriesPer100g: 295, proteinPer100g: 17, carbsPer100g: 24, fatPer100g: 14, defaultServingG: 200),
        NutritionEntry(name: "Hot Dog", aliases: ["hot dog", "perrito caliente"], caloriesPer100g: 290, proteinPer100g: 10, carbsPer100g: 24, fatPer100g: 18, defaultServingG: 100),
        NutritionEntry(name: "French Fries", aliases: ["french fries", "fries", "frite", "chips", "patatas fritas", "frites", "papas fritas"], caloriesPer100g: 312, proteinPer100g: 3.4, carbsPer100g: 41, fatPer100g: 15, defaultServingG: 150),
        NutritionEntry(name: "Fried Chicken", aliases: ["fried chicken", "chicken nuggets", "nuggets", "pollo frito", "poulet frit"], caloriesPer100g: 260, proteinPer100g: 19, carbsPer100g: 10, fatPer100g: 16, defaultServingG: 150),
        NutritionEntry(name: "Burrito", aliases: ["burrito"], caloriesPer100g: 163, proteinPer100g: 7, carbsPer100g: 20, fatPer100g: 6, defaultServingG: 300),
        NutritionEntry(name: "Taco", aliases: ["taco", "tacos"], caloriesPer100g: 226, proteinPer100g: 9, carbsPer100g: 20, fatPer100g: 13, defaultServingG: 100),
        NutritionEntry(name: "Sushi Roll", aliases: ["sushi", "sushi roll", "maki", "california roll"], caloriesPer100g: 150, proteinPer100g: 6, carbsPer100g: 29, fatPer100g: 2, defaultServingG: 120),
        NutritionEntry(name: "Ramen", aliases: ["ramen", "ramen noodles", "instant noodles", "noodle soup"], caloriesPer100g: 138, proteinPer100g: 5, carbsPer100g: 26, fatPer100g: 2, defaultServingG: 400),
        NutritionEntry(name: "Fried Rice", aliases: ["fried rice", "arroz frito", "riz frit"], caloriesPer100g: 163, proteinPer100g: 4, carbsPer100g: 24, fatPer100g: 6, defaultServingG: 250),
        NutritionEntry(name: "Curry", aliases: ["curry", "chicken curry", "curry de pollo"], caloriesPer100g: 116, proteinPer100g: 8, carbsPer100g: 8, fatPer100g: 6, defaultServingG: 250),
        NutritionEntry(name: "Paella", aliases: ["paella"], caloriesPer100g: 140, proteinPer100g: 8, carbsPer100g: 18, fatPer100g: 4, defaultServingG: 300),
        NutritionEntry(name: "Lasagna", aliases: ["lasagna", "lasaña", "lasagne"], caloriesPer100g: 135, proteinPer100g: 8, carbsPer100g: 15, fatPer100g: 5, defaultServingG: 250),
        NutritionEntry(name: "Mac and Cheese", aliases: ["mac and cheese", "macaroni and cheese", "macarrones con queso"], caloriesPer100g: 164, proteinPer100g: 7, carbsPer100g: 17, fatPer100g: 8, defaultServingG: 200),
        NutritionEntry(name: "Sandwich", aliases: ["sandwich", "bocadillo", "bocata"], caloriesPer100g: 250, proteinPer100g: 10, carbsPer100g: 30, fatPer100g: 10, defaultServingG: 150),
        NutritionEntry(name: "Caesar Salad", aliases: ["caesar salad", "ensalada cesar", "salade césar"], caloriesPer100g: 127, proteinPer100g: 7, carbsPer100g: 7, fatPer100g: 9, defaultServingG: 200),
        NutritionEntry(name: "Quesadilla", aliases: ["quesadilla"], caloriesPer100g: 250, proteinPer100g: 10, carbsPer100g: 26, fatPer100g: 12, defaultServingG: 150),
        NutritionEntry(name: "Fish Sticks", aliases: ["fish sticks", "fish fingers", "palitos de pescado", "bâtonnets de poisson"], caloriesPer100g: 230, proteinPer100g: 12, carbsPer100g: 20, fatPer100g: 11, defaultServingG: 100),

        // --- Snacks ---
        NutritionEntry(name: "Potato Chips", aliases: ["potato chips", "crisps", "patatas de bolsa", "chips de pomme de terre"], caloriesPer100g: 536, proteinPer100g: 7, carbsPer100g: 53, fatPer100g: 35, defaultServingG: 30),
        NutritionEntry(name: "Popcorn", aliases: ["popcorn", "palomitas", "pop-corn"], caloriesPer100g: 387, proteinPer100g: 13, carbsPer100g: 78, fatPer100g: 4.5, defaultServingG: 30),
        NutritionEntry(name: "Crackers", aliases: ["crackers", "galletas saladas", "biscuits salés"], caloriesPer100g: 484, proteinPer100g: 8, carbsPer100g: 73, fatPer100g: 18, defaultServingG: 30),
        NutritionEntry(name: "Pretzels", aliases: ["pretzels", "pretzel"], caloriesPer100g: 380, proteinPer100g: 10, carbsPer100g: 80, fatPer100g: 3, defaultServingG: 30),

        // --- Desserts / Sweets ---
        NutritionEntry(name: "Cookie", aliases: ["cookie", "cookies", "biscuit", "galleta", "galletas"], caloriesPer100g: 488, proteinPer100g: 5, carbsPer100g: 65, fatPer100g: 23, defaultServingG: 30),
        NutritionEntry(name: "Brownie", aliases: ["brownie", "brownies"], caloriesPer100g: 466, proteinPer100g: 6, carbsPer100g: 54, fatPer100g: 26, defaultServingG: 60),
        NutritionEntry(name: "Cake", aliases: ["cake", "tarta", "gâteau", "bizcocho", "pastel"], caloriesPer100g: 350, proteinPer100g: 5, carbsPer100g: 52, fatPer100g: 15, defaultServingG: 80),
        NutritionEntry(name: "Cheesecake", aliases: ["cheesecake", "tarta de queso"], caloriesPer100g: 321, proteinPer100g: 6, carbsPer100g: 26, fatPer100g: 22, defaultServingG: 100),
        NutritionEntry(name: "Ice Cream", aliases: ["ice cream", "helado", "glace", "gelato"], caloriesPer100g: 207, proteinPer100g: 3.5, carbsPer100g: 24, fatPer100g: 11, defaultServingG: 66),
        NutritionEntry(name: "Donut", aliases: ["donut", "doughnut", "dona", "rosquilla", "beignet"], caloriesPer100g: 452, proteinPer100g: 5, carbsPer100g: 51, fatPer100g: 25, defaultServingG: 60),
        NutritionEntry(name: "Muffin", aliases: ["muffin", "magdalena"], caloriesPer100g: 340, proteinPer100g: 5, carbsPer100g: 50, fatPer100g: 13, defaultServingG: 110),
        NutritionEntry(name: "Dark Chocolate", aliases: ["dark chocolate", "chocolate", "chocolate negro", "chocolat noir", "chocolat"], caloriesPer100g: 546, proteinPer100g: 5, carbsPer100g: 60, fatPer100g: 31, defaultServingG: 30),
        NutritionEntry(name: "Milk Chocolate", aliases: ["milk chocolate", "chocolate con leche", "chocolat au lait"], caloriesPer100g: 535, proteinPer100g: 8, carbsPer100g: 59, fatPer100g: 30, defaultServingG: 30),

        // --- Deli Meats ---
        NutritionEntry(name: "Ham", aliases: ["ham", "jamon", "jamón", "turkey ham", "jambon", "jamón serrano", "jamón york", "prosciutto"], caloriesPer100g: 145, proteinPer100g: 21, carbsPer100g: 1.5, fatPer100g: 5.5, defaultServingG: 50),
        NutritionEntry(name: "Bacon", aliases: ["bacon", "beicon", "lard fumé", "panceta"], caloriesPer100g: 541, proteinPer100g: 37, carbsPer100g: 1.4, fatPer100g: 42, defaultServingG: 30),
        NutritionEntry(name: "Salami", aliases: ["salami", "pepperoni", "chorizo", "salchichón", "saucisson"], caloriesPer100g: 336, proteinPer100g: 22, carbsPer100g: 1, fatPer100g: 26, defaultServingG: 30),
        NutritionEntry(name: "Sausage", aliases: ["sausage", "salchicha", "saucisse", "bratwurst", "frankfurter"], caloriesPer100g: 301, proteinPer100g: 12, carbsPer100g: 2, fatPer100g: 27, defaultServingG: 100),

        // --- Condiments / Extras ---
        NutritionEntry(name: "Sugar", aliases: ["sugar", "azúcar", "sucre"], caloriesPer100g: 387, proteinPer100g: 0, carbsPer100g: 100, fatPer100g: 0, defaultServingG: 10),
        NutritionEntry(name: "Honey", aliases: ["honey", "miel"], caloriesPer100g: 304, proteinPer100g: 0.3, carbsPer100g: 82, fatPer100g: 0, defaultServingG: 21),
        NutritionEntry(name: "Maple Syrup", aliases: ["maple syrup", "sirope de arce", "sirop d'érable"], caloriesPer100g: 260, proteinPer100g: 0, carbsPer100g: 67, fatPer100g: 0.1, defaultServingG: 30),
        NutritionEntry(name: "Jam", aliases: ["jam", "jelly", "mermelada", "confiture"], caloriesPer100g: 250, proteinPer100g: 0.4, carbsPer100g: 63, fatPer100g: 0.1, defaultServingG: 20),
        NutritionEntry(name: "Nutella", aliases: ["nutella", "nocilla", "chocolate spread", "crema de cacao"], caloriesPer100g: 539, proteinPer100g: 6.3, carbsPer100g: 58, fatPer100g: 30, defaultServingG: 30),
        NutritionEntry(name: "Ketchup", aliases: ["ketchup", "catsup"], caloriesPer100g: 112, proteinPer100g: 1.7, carbsPer100g: 26, fatPer100g: 0.1, defaultServingG: 15),
        NutritionEntry(name: "Mustard", aliases: ["mustard", "mostaza", "moutarde"], caloriesPer100g: 66, proteinPer100g: 4, carbsPer100g: 6, fatPer100g: 4, defaultServingG: 10),
        NutritionEntry(name: "Mayo", aliases: ["mayo", "mayonnaise", "mayonesa"], caloriesPer100g: 680, proteinPer100g: 1, carbsPer100g: 0.6, fatPer100g: 75, defaultServingG: 15),
        NutritionEntry(name: "Hummus", aliases: ["hummus", "houmous"], caloriesPer100g: 166, proteinPer100g: 8, carbsPer100g: 14, fatPer100g: 10, defaultServingG: 30),
        NutritionEntry(name: "Guacamole", aliases: ["guacamole"], caloriesPer100g: 160, proteinPer100g: 2, carbsPer100g: 9, fatPer100g: 15, defaultServingG: 30),
        NutritionEntry(name: "Soy Sauce", aliases: ["soy sauce", "salsa de soja", "sauce soja"], caloriesPer100g: 53, proteinPer100g: 8, carbsPer100g: 5, fatPer100g: 0, defaultServingG: 15),
        NutritionEntry(name: "Pesto Sauce", aliases: ["pesto", "pesto sauce", "salsa pesto"], caloriesPer100g: 387, proteinPer100g: 5, carbsPer100g: 6, fatPer100g: 38, defaultServingG: 30),
        NutritionEntry(name: "Vinaigrette", aliases: ["vinaigrette", "salad dressing", "aderezo", "vinagreta"], caloriesPer100g: 210, proteinPer100g: 0.3, carbsPer100g: 8, fatPer100g: 20, defaultServingG: 30),

        // --- Bars / Supplements ---
        NutritionEntry(name: "Protein Bar", aliases: ["protein bar", "barrita de proteina", "barre protéinée"], caloriesPer100g: 350, proteinPer100g: 30, carbsPer100g: 35, fatPer100g: 10, defaultServingG: 60),
        NutritionEntry(name: "Granola", aliases: ["granola", "muesli"], caloriesPer100g: 489, proteinPer100g: 10, carbsPer100g: 64, fatPer100g: 20, defaultServingG: 50),
        NutritionEntry(name: "Cereal Bar", aliases: ["cereal bar", "barrita de cereales", "barre de céréales"], caloriesPer100g: 400, proteinPer100g: 5, carbsPer100g: 70, fatPer100g: 12, defaultServingG: 30),
    ]

    // MARK: - Lookup

    /// Pre-built dictionary for O(1) exact alias matches (built once at init).
    private let aliasIndex: [String: NutritionEntry]

    init() {
        var index: [String: NutritionEntry] = [:]
        for entry in entries {
            for alias in entry.aliases {
                index[alias] = entry
            }
        }
        self.aliasIndex = index
    }

    /// Check if `text` contains `word` as a whole word (not as a substring of another word).
    private func containsWholeWord(_ text: String, _ word: String) -> Bool {
        let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: word) + #"\b"#
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    /// Fuzzy-match a food query against the database.
    func lookup(_ query: String) -> NutritionEntry? {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return nil }

        // O(1) exact alias match
        if let entry = aliasIndex[q] { return entry }

        // Query contains an alias as whole word(s)
        // e.g., "grilled chicken breast" contains "chicken breast"
        // but "milkshake" does NOT match "hake" (substring, not whole word)
        var bestMatch: NutritionEntry?
        var bestLength = 0
        for entry in entries {
            for alias in entry.aliases {
                if containsWholeWord(q, alias) && alias.count > bestLength {
                    bestMatch = entry
                    bestLength = alias.count
                }
            }
        }
        if let match = bestMatch { return match }

        // Alias contains query as whole word (e.g., query "salmon" matches alias "salmon fillet")
        // Only for short queries to avoid false positives on long text
        if q.split(separator: " ").count <= 3 {
            for entry in entries {
                for alias in entry.aliases {
                    if containsWholeWord(alias, q) { return entry }
                }
            }
        }

        return nil
    }

    // MARK: - Quantity Parsing for LLM-Extracted Items

    /// Parses a quantity string from LLM extraction into grams.
    /// Handles: "200g", "200", "2", "150ml", "1 cup", "2 slices"
    /// When no unit is given and the value is small (≤10), treats as count × defaultServing.
    /// Pass `defaultServingG` from the already-resolved entry to avoid a redundant lookup.
    func parseQuantityToGrams(_ qty: String, defaultServingG: Double?) -> Double? {
        let text = qty.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else { return nil }

        // "200g", "200gr", "200 grams"
        if let match = text.range(of: #"^(\d+(?:\.\d+)?)\s*(?:g|gr|grams?)$"#, options: .regularExpression) {
            let numStr = String(text[match]).filter { $0.isNumber || $0 == "." }
            return Double(numStr)
        }

        // "150ml"
        if let match = text.range(of: #"^(\d+(?:\.\d+)?)\s*ml$"#, options: .regularExpression) {
            let numStr = String(text[match]).filter { $0.isNumber || $0 == "." }
            return Double(numStr)
        }

        // Unit-based quantities: "1 tbsp", "2 cups", "3 slices", etc.
        let unitConversions: [(pattern: String, grams: Double)] = [
            ("tbsp", 14), ("tablespoons?", 14),
            ("tsp", 5), ("teaspoons?", 5),
            ("cups?", 240), ("glass(?:es)?", 240),
            ("slices?", 30), ("scoops?", 30),
            ("handfuls?", 30),
        ]
        for (unit, unitGrams) in unitConversions {
            let pattern = #"^(\d+(?:\.\d+)?)\s*"# + unit + "$"
            if text.range(of: pattern, options: .regularExpression) != nil {
                let numStr = text.filter { $0.isNumber || $0 == "." }
                let count = Double(numStr) ?? 1
                return count * unitGrams
            }
        }

        // "some", "a serving", or other vague quantities — use default
        if text == "some" || text == "a serving" || text == "a portion" {
            return nil // will fall back to defaultServingG
        }

        // Plain number: "200" (grams) or "2" (count)
        if let value = Double(text) {
            if value <= 10 {
                // Treat as count — multiply by default serving
                return value * (defaultServingG ?? 100)
            }
            // Treat as grams directly
            return value
        }

        return nil
    }
}
