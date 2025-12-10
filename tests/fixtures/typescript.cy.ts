import { foo } from "bar";
import type { MyType } from "baz";

describe("typescript features", () => {
  it("should handle typescript syntax", () => {
    const data: MyType = { name: "test" };
    expect(data.name).toBe("test");
  });

  it.skip("should be skipped", () => {
    // this test is skipped
  });

  it.only("should be focused", () => {
    expect(true).toBe(true);
  });
});
