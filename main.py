"""A simple demonstration of how RSA signatures work

You can read about the underlying logic on Wikipedia, the basis for this demo:
https://en.wikipedia.org/w/index.php?title=RSA_(cryptosystem)&oldid=1151951878#Operation (CC-BY-SA-3.0)
Gist: https://gist.github.com/cam-rod/52dcd6b7e558c2a3f248df665be47b93
"""

import hashlib
from cryptography.hazmat.primitives import padding

# Shared constants
MODULUS = 3233


def pad(enc_msg: bytes) -> bytes:
    """
    :param enc_msg: a bytes-encoded message (in this case UTF-8)
    :return: The PKCS #7-padded message
    """
    padder = padding.PKCS7(128).padder()
    return padder.update(enc_msg) + padder.finalize()


def hasher(padded_msg: bytes) -> str:
    """
    :param padded_msg: The padded message
    :return: A string representing the SHA256 digest of the message
    """
    hashed_msg_str = '0x' + hashlib.sha256(padded_msg).hexdigest()
    return hashed_msg_str


def sign(hashed_msg_int: int) -> int:
    """
    :param hashed_msg_int: SHA256 digest of the padded message
    :return: An RSA-like signature
    """
    private_key = 17
    return pow(hashed_msg_int, private_key, MODULUS)  # (hash ^ private_key) % MODULUS


def verify(msg_signature: int) -> int:
    """
    :param msg_signature: The signature of the padded message
    :return: The remainder of the signature raised to the public key
    """
    public_key = 413
    return pow(msg_signature, public_key, MODULUS)  # (msg_signature ^ public_key) % MODULUS


def main():
    # Alice

    alice_msg = "Alice sent this message"
    print("Alice would like to sign the following message, to prove she sent it:\n" + alice_msg)

    alice_enc_msg = alice_msg.encode('utf-8')
    alice_padded_msg = pad(alice_enc_msg)
    print(f"\nPadded message: \"{alice_padded_msg}\"")

    alice_hashed_msg = hasher(alice_padded_msg)
    print("SHA256 digest: " + alice_hashed_msg)

    signature = sign(int(alice_hashed_msg, 16))
    print("Message signature: " + hex(signature))

    # Bob

    print("\n" + ('-' * 65) + "\n")
    print("Bob would like to verify that Alice sent the message:.\n" +
          "Bob receives both the message, and the signature. He can\n" +
          "recalculate the hash to verify the signature.")

    bob_msg = alice_msg
    bob_enc_msg = bob_msg.encode('utf-8')
    bob_padded_msg = pad(bob_enc_msg)
    print(f"\nPadded message: \"{bob_padded_msg}\"")

    bob_hashed_msg = hasher(bob_padded_msg)
    print("SHA256 digest: " + alice_hashed_msg)

    bob_hash_remainder = pow(int(bob_hashed_msg, 16), 1, MODULUS)  # bob_hashed_msg % MODULUS
    print("Remainder of hash: " + hex(bob_hash_remainder))

    print(hex(signature))
    decoded_sig = verify(signature)
    print("Decoded signature: " + hex(decoded_sig))

    if bob_hash_remainder == decoded_sig:
        print("Match! This message was signed by Alice's private key.")
    else:
        print("WARNING: Signature does not match provided message")
    input("\nPress Enter to see an example of the math used...")

    # Math explained
    print("-" * 65 + "\nPRIV key: 17 || PUB key: 413 || Modulus: 3233")
    print("17 * 413 = 3233")

    print(f"\n5 % 3233 = {pow(5,1,3233)} (hash to check against)")
    print(f"\n5^PRIV % 3233 = 5^17 % 3233 = {pow(5,17,3233)} (signature)")
    print(f"3086^PUB % 3233 = 3086^413 % 3233 = {pow(3086,17, 3233)}")

    print("\n5 mod 3233 == ((5^17)^413) mod 3233 == ((5^413)^17) mod 3233 == 5")


if __name__ == '__main__':
    main()
