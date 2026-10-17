#!/bin/bash
set -e

if [[ -z "$1" ]]; then
  echo "Please provide an element as an argument."
  exit 0
fi

element=$(psql -X -qAt -U freecodecamp -d periodic_table -v search_term="$1" <<SQL
SELECT e.atomic_number::text || chr(9) || e.symbol || chr(9) || e.name || chr(9) || p.atomic_mass::text || chr(9) || t.type || chr(9) || p.melting_point_celsius::text || chr(9) || p.boiling_point_celsius::text
FROM elements e
JOIN properties p USING (atomic_number)
JOIN types t USING (type_id)
WHERE e.atomic_number::text = :'search_term'
   OR e.symbol = :'search_term'
   OR e.name = :'search_term';
SQL
)

if [[ -z "$element" ]]; then
  echo "I could not find that element in the database."
  exit 0
fi

IFS=$'\t' read -r atomic_number symbol name atomic_mass type melting_point boiling_point <<< "$element"
printf "The element with atomic number %s is %s (%s). It's a %s, with a mass of %s amu. %s has a melting point of %s celsius and a boiling point of %s celsius.\n" \
  "$atomic_number" "$name" "$symbol" "$type" "$atomic_mass" "$name" "$melting_point" "$boiling_point"