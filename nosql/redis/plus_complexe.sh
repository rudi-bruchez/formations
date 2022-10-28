redis-cli incr next.books.id
redis-cli sadd books:1:title "The Omnivore's Dilemma"
redis-cli sadd books:1:author "Michael Pollan"
redis-cli sadd books:1:tags 1
redis-cli sadd books:1:tags 2
redis-cli sadd books:1:tags 3
redis-cli sadd books:1:tags 4
redis-cli sadd books:1:tags 5
redis-cli sadd books:1:tags 6
redis-cli sadd tag:1:name "organic"
redis-cli sadd tag:2:name "industrialization"
redis-cli sadd tag:3:name "local"
redis-cli sadd tag:4:name "written by a journalist"
redis-cli sadd tag:5:name "best seller"
redis-cli sadd tag:6:name "insight"
redis-cli sadd tag:1:books
redis-cli sadd tag:2:books
redis-cli sadd tag:3:books
redis-cli sadd tag:4:books
redis-cli sadd tag:5:books
redis-cli sadd tag:6:books
redis-cli incr next.books.id
redis-cli sadd books:2:title "Outliers"
redis-cli sadd books:2:author "Malcolm Gladwell"
redis-cli sadd books:2:tags 6
redis-cli sadd books:2:tags 5
redis-cli sadd books:2:tags 4
redis-cli sadd tag:4:books 2
redis-cli sadd tag:5:books 2
redis-cli sadd tag:6:books 2
redis-cli smembers books:1:title
redis-cli smembers books:1:author
redis-cli smembers books:1:tags
redis-cli smembers books:2:title
redis-cli smembers books:2:author
redis-cli smembers books:2:tags

# un AND
redis-cli sinter tag:1:books tag:6:books

# un OR
redis-cli sunion tag:1:books tag:6:books

# AND NOT
redis-cli sdiff tag:5:books tag:6:books

