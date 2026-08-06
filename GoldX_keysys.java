package keysys;

import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.X509EncodedKeySpec;
import java.time.Instant;
import java.util.Base64;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class GoldX_keysys {

    private static final String PUBLIC_KEY_BASE64 =
            "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArVbH3DetnwAMJkK8UwPhy9XqBhJqZMUwrfgqNbBAeguF4/X+xs0CR4bPnUYHve+9NLfSmFLBXGcd6DIclrp8p/jaRpkrpObYC9dFb2ma0RA3LpzuH4iIlRbFNeD9rGDRgiEF1HNK/qG2Sqy+gVoLmZlGqDnoqqxkAnncI4xOl34/GIu38Xvcs/TsguoYI19JaBRmtOeVlhUbi275dRa8SJxSo4rwNkDpNUXDDK63INHLKXPCu65CHQzdijnZaC/+ymkCKHboF5BosMDqTiXRJi2KWRDm9T8fdJ06niqEvhxfIVtlq7wR0F63vNzgi97zMGtCoeNI5GUZjh6aDJc3awIDAQAB";

    // Maximale Gültigkeit / Toleranz auf 15 Minuten (900s) erhöht
    private static final long MAX_AGE_SECONDS = 900;

    public static boolean verifyLicense(String rawLicenseKey) {
        try {
            byte[] decodedBytes = Base64.getDecoder().decode(rawLicenseKey.trim());
            String jsonString = new String(decodedBytes, StandardCharsets.UTF_8);

            String username = extractJsonValue(jsonString, "user");
            String tsStr = extractJsonValue(jsonString, "ts");
            String signatureBase64 = extractJsonValue(jsonString, "sig");

            if (username == null || tsStr == null || signatureBase64 == null) {
                System.err.println("[GOLDx_keysys] Invalid JSON format.");
                return false;
            }

            long timestamp = Long.parseLong(tsStr);

            // 1. Automatische Umrechnung: Millisekunden → Sekunden
            if (timestamp > 9999999999L) {
                timestamp = timestamp / 1000;
            }

            // 2. Signatur-Echtheit prüfen
            String payload = username + "|" + timestamp;
            if (!verifyRsaSignature(payload, signatureBase64)) {
                System.err.println("[GOLDx_keysys] Invalid signature! The key has been forged.");
                return false;
            }

            // 3. Zeitstempel prüfen
            long currentTimestamp = Instant.now().getEpochSecond();
            long ageInSeconds = currentTimestamp - timestamp;

            // Debug-Ausgabe zur Diagnose der Zeitabweichung
            System.out.println("[GOLDx_keysys] Time Difference: " + ageInSeconds + "s (Current: " + currentTimestamp + ", Key: " + timestamp + ")");

            if (ageInSeconds > MAX_AGE_SECONDS) {
                System.err.println("[GOLDx_keysys] Key has expired (" + ageInSeconds + "s old).");
                return false;
            }

            if (ageInSeconds < -300) {
                System.err.println("[GOLDx_keysys] Time desynchronization: PC system clock is too far behind (" + ageInSeconds + "s).");
                return false;
            }

            System.out.println("[GOLDx_keysys] Your key is valid! Welcome, " + username + "!");
            return true;

        } catch (Exception e) {
            System.err.println("[GOLDx_keysys] Invalid key format or verification error: " + e.getMessage());
            return false;
        }
    }

    private static String extractJsonValue(String json, String key) {
        Pattern pattern = Pattern.compile("\"" + key + "\"\\s*:\\s*(?:\"([^\"]*)\"|([0-9]+))");
        Matcher matcher = pattern.matcher(json);
        if (matcher.find()) {
            return matcher.group(1) != null ? matcher.group(1) : matcher.group(2);
        }
        return null;
    }

    private static boolean verifyRsaSignature(String data, String signatureBase64) throws Exception {
        byte[] publicBytes = Base64.getDecoder().decode(PUBLIC_KEY_BASE64.replaceAll("\\s+", ""));
        X509EncodedKeySpec keySpec = new X509EncodedKeySpec(publicBytes);
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        PublicKey publicKey = keyFactory.generatePublic(keySpec);

        Signature sig = Signature.getInstance("SHA256withRSA");
        sig.initVerify(publicKey);
        sig.update(data.getBytes(StandardCharsets.UTF_8));

        byte[] signatureBytes = Base64.getDecoder().decode(signatureBase64);
        return sig.verify(signatureBytes);
    }

    public static void main(String[] args) {
        String keyToVerify;

        // Nutze das übergebene Argument aus install.ps1, falls vorhanden
        if (args.length > 0 && !args[0].isEmpty()) {
            keyToVerify = args[0];
        } else {
            // Fallback für Tests direkt in der IDE
            keyToVerify = "eyJ1c2VyIjoie3VzZXIudXNlcm5hbWV9IiwidHMiOjE3ODYwNDI2ODksInNpZyI6IkNsY1c4VE1qb01TbnhJbDV5MjRRTEtTMW1mNnJac2o1YzZjTkdld2dBMXVvVTdHaDlhZmFIWHE0QkUvNW53TDBvZ29kbkUzVzJrdHJrUjN0V2dvSW5lZmZPbm9aM2RXMlR2Wkh5WkpobVFYdE9FSmVhVnUweUhYTlR4ZjZRQzgzNTJlSzFrcGhVV3FjN2JLY3lJNW5XYkM5b1dOazJMQ0hkUCtNYS9yVUdVd3R4TTk0czdHcnZ2ejVURGxsbzlVUi9Fc2VHM29GMTYxUWJPTnI0MUZ1b05hZkc4ZlNjTDExeWVwNFl1NzVtVlZFR3dlWkNQeUtrUUdzNnpIV1ZPS2gwNjFnd2dHMlplRzdZZGlvRVlzZ2xDbkNoT3o5ZzBPSFRFWjB3Q2x2SUxya2NIcXdiQnJGVXQ0RS8zUVppa0V2c0ZPWDNFVVFjN2lzQkh1czV0NmZtQT09In0=";
        }

        boolean isValid = verifyLicense(keyToVerify);
        if (isValid) {
            System.exit(0);
        } else {
            System.exit(1);
        }
    }
}