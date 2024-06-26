hitzhangjie:
------------------------------------------------------------------------------
how does linux calculate random number by the so-called entropy?

ps: 
- reading from /dev/random is blocking for collecting enough entropy to prevent generating predictable random numbers.
- reading from /dev/urandom is non-blocking, it's a variant of /dev/random for high safety but not cryptographically safe occasions.

gemma:
------------------------------------------------------------------------------
**Linux calculates random numbers using a combination of hardware-based entropy and statistical analysis:**

**1. Entropy collection:**

- Linux collects entropy from various hardware sources such as:
    - Keyboard and mouse movements
    - Network interface card (NIC) activity
    - Timer interrupts
    - Random voltage fluctuations from electronic components

**2. Hashing:**

- The collected data is passed through a cryptographically secure hash function, such as SHA-1 or Whirlpool.
- Hashing ensures that the output is highly unpredictable and resistant to collisions.

**3. Statistical analysis:**

- The hashed data is then statistically analyzed to remove any remaining biases or patterns.
- This process ensures that the final output is truly random and statistically indistinguishable from true randomness.

**4. Random number generation:**

- Once the entropy is collected and statistically analyzed, the resulting random bytes are stored in a buffer.
- Applications can read from /dev/random to obtain a stream of random numbers.

**Entropy measurement:**

- Linux tracks the amount of entropy collected from each hardware source.
- The system maintains a threshold for the amount of entropy required before it considers the collection statistically sufficient.
- If the threshold is not met, reading from /dev/random will block until enough entropy has been collected.

**Factors influencing entropy collection:**

- Hardware configuration and quality
- System activity and load
- Time since the last entropy collection

**Purpose of statistical analysis:**

- To remove any remaining patterns or biases in the collected data.
- To ensure that the generated random numbers are truly random and not predictable
