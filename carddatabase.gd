const SUITS = ["S", "H", "C", "D"]
const NUMBERS = ["2","3","4","5","6","7","8","9","10"]
const FACES = ["j", "q", "k"]

const CARD_BACK_NAMES = ["Back0", "Back1", "Back2", "BackEye", "BackEyeR", "BackW"]

var CARD_BACK = {}
var CARDS = {}

func init_cards():
	# Aces
	CARDS["Aces/AOS"] = []
	CARDS["Aces/AOH"] = []
	CARDS["Aces/AOC"] = []
	CARDS["Aces/AOD"] = []

	# Number cards
	for suit in SUITS:
		for num in NUMBERS:
			CARDS[suit + num] = []

	# Face cards
	for suit in SUITS:
		for face in FACES:
			CARDS[suit + face] = []

func init_card_backs():
	for name in CARD_BACK_NAMES:
		CARD_BACK[name] = []
