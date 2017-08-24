﻿using System.Configuration;
using NUnit.Framework;

namespace HelloAzureCIUnitTests
{
    [TestFixture]
    public class ConfigurationSettings
    {
        [Test]
        public void Should_not_be_null()
        {
            var helloTarget = ConfigurationManager.AppSettings["HelloTarget"];

            Assert.That(helloTarget, Is.Not.EqualTo(null));
        }
        [Test]
        public void Should_be_specific_to_Azure_environment()
        {
            var helloTarget = ConfigurationManager.AppSettings["HelloTarget"];

            Assert.That(helloTarget, Is.Not.EqualTo("Azure"));
        }
    }
}
