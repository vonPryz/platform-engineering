import { describe, expect, test } from "vitest";
import { isReleaseCandidateOk } from "../app/app";

describe("CI gate demo", () => {
  test("release candidate passes basic check", () => {
    expect(isReleaseCandidateOk()).toBe(true);
  });
});
