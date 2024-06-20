import re
import math
from collections import Counter

file_path = "./dataset/dr5hn/subregions.csv"
separators = [
    " ",
    "!",
    "'",
    "(",
    ")",
    ",",
    "-",
    ".",
    ":",
    ";",
    "?",
    "[",
    "\n",
    "]",
    "|",
]


class SequentialIDGenerator:
    def __init__(self, characters):
        self.characters = characters
        self.base = len(characters)
        self.counter = 0

    def get_next_id(self):
        current = self.counter
        self.counter += 1

        # Convert the counter to a string using the characters in the table
        id_str = ""
        while current >= 0:
            id_str = self.characters[current % self.base] + id_str
            current = current // self.base - 1

        return f"{codekey}{id_str}"


codekey = "®"
characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"[:]
lenchar = len(characters)


def get_dictIdSize(characters, nblines):
    nblines = max(1, nblines)
    base = len(characters)
    rank = math.ceil(math.log(nblines) / math.log(base))

    return max(1, rank)


def getDictionary(text, separators):
    # Split words
    regex_pattern = "|".join(map(re.escape, separators))
    words = re.split(regex_pattern, text)

    # Count word occurrences
    word_count = Counter(words)
    if "" in word_count:
        del word_count[""]

    # filter
    filtered_words = {word: count for word, count in word_count.items() if count > 1}
    filtered_words = sorted(filtered_words.items(), key=lambda d: d[1], reverse=True)

    selected_words = []
    for word, count in filtered_words:
        # codekey+id
        dictsize = get_dictIdSize(characters, len(selected_words)) + 1
        # print(
        #     f'"{dictsize < len(word)} => {word}({count}) dicsize:{get_dictIdSize(characters, len(selected_words))+1} < lenword:{len(word)}'
        # )

        # codekey + word entry that must lower than word size
        if dictsize < len(word):  # and count * dictsize < len(word):
            selected_words.append(word)

    return selected_words


def remplacer_mots_avec_dictionnaire(texte, dictionnaire_remplacement):
    for mot, remplacement in dictionnaire_remplacement.items():
        texte = texte.replace(mot, remplacement)
    return texte


# Lire le fichier
with open(file_path, "r", encoding="utf-8") as file:
    text = file.read()

# Créer le dictionnaire de fréquence des mots
word_frequency_dict = getDictionary(text, separators)
with open("dictionary.txt", "w") as file:
    for word in word_frequency_dict:
        file.write(f"{word}\n")

generator = SequentialIDGenerator(characters)

# Calcul la liste des mots à remplacer pour compression
replace_words = {}
for word in word_frequency_dict:
    replace_words[word] = generator.get_next_id()

compressed = remplacer_mots_avec_dictionnaire(text, replace_words)
print(compressed)

with open("compressed.txt", "w") as file:
    file.write(compressed)

# Calcul la liste des mots à remplacer pour décompression
replace_words = {}
for word in word_frequency_dict:
    replace_words[generator.get_next_id()] = word

decompressed = remplacer_mots_avec_dictionnaire(compressed, replace_words)
print(decompressed)
with open("decompressed.txt", "w") as file:
    file.write(decompressed)
