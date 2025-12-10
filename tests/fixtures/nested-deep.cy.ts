describe("Level 1", () => {
  it("should be at level 1", () => {
    expect(true).toBe(true);
  });

  describe("Level 2", () => {
    it("should be at level 2", () => {
      expect(true).toBe(true);
    });

    describe("Level 3", () => {
      it("should be at level 3", () => {
        expect(true).toBe(true);
      });

      describe("Level 4", () => {
        it("should be at level 4", () => {
          expect(true).toBe(true);
        });

        describe("Level 5", () => {
          it("should be at level 5", () => {
            expect(true).toBe(true);
          });
        });
      });
    });
  });
});