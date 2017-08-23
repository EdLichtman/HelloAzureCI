using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using HelloAzureCI.Models;

namespace HelloAzureCI.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            var helloTarget = ConfigurationManager.AppSettings["HelloTarget"];
            return View(new IndexModel {World = helloTarget});
        }

        public ActionResult About()
        {
            ViewBag.Message = "Your application description page.";

            return View();
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "Your contact page.";

            return View();
        }
    }
}