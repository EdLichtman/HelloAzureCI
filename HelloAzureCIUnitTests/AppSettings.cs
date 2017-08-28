using System;
using System.Configuration;
using NUnit.Framework;

namespace HelloAzureCIUnitTests
{
    [TestFixture]
    public class AppSettings
    {

        [Test]
        public void Should_not_be_null()
        {
            string helloTarget = ConfigurationManager.AppSettings["HelloTarget"];

            Assert.That(helloTarget, Is.Not.EqualTo(null));
        }
        [Test]
        public void Should_be_specific_to_Azure_environment()
        {
            string helloTarget = ConfigurationManager.AppSettings["HelloTarget"];

            Assert.That(helloTarget, Is.Not.EqualTo("Azure"));
        }

        [Test]
        public void Should_run_Assert_That_and_Is_EqualTo_without_any_problems()
        {
            try
            {
                Assert.That(1, Is.EqualTo(1));
            }
            catch (Exception e)
            {
                throw new Exception("Failed asserting that 1 Is.EqualTo(1), must be Assert.That or the Is.* that's failing", e.InnerException); 
            }
        }

        [Test]
        public void Should_run_Assert_without_any_problems()
        {
            try
            {
                Assert.AreEqual(1, 1);
            }
            catch (Exception e)
            {
                throw new Exception("Failed asserting that AreEqual(1, 1), must be Assert that's failing", e.InnerException);
            }
        }

    }
}
