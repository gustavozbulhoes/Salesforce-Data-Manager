@isTest
private class CICDTest {
    @isTest
    private static void CICDTest() {
        double result = CICD.add(2,3);
        assert.areEqual(5,result,'2 + 3 = 5 was expected');
    }
}