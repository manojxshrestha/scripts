## **Usage**
Use it like this way:
```bash
./subburst.sh example.com | tee -a dnsx-IN.txt
```

Then, run `dnsx`:
```bash
cat dnsx-IN.txt | dnsx -retry 3 -threads 300 -resp -no-color -stats -silent -a -aaaa -cname | tee -a dnsx-OUT.txt
```

## Subdomains Permutation AND Alterations
#  1 - Generate Permutation AND Alterations

```bash
gotator -sub GOOD-Subdomains.txt -perm commonwords.txt -prefixes -silent -depth 2 -mindup -md  -adv -numbers 5 | tee -a gotator-OUT.txt
```

#    2 - Resolvable Subdomains
```bash
tor-OUT.txt | dnsx -retry 3 -threads 300 -resp -no-color -stats -silent -a -aaaa -cname | tee -a dnsx-OUT.txt
```

## Wildcard
```bash
./filter-wildcard.sh allsubdomains.txt
```
