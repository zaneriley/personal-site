import Link from "next/Link";
import {H1,P, Cheee} from "../../components/typography";
import {Grid} from "../../components/grid";

export default function BuildingCohesiveProducts() {
  return (
    <Grid>
      <H1>Building cohesive products through design ops</H1>
      <h2>
        <Link href="/">
          <a>Back to home</a>
        </Link>
      </h2>
  
      <P typeface="Cheee">
        <Cheee>NerdWallet</Cheee> wanted to grow from giving financial advice to helping people manage their finances, and 
        asked me to build a design system to keep the products cohesive. 
      </P>

      <P>
        I designed systems and tools that lead to more 
        efficient product cycles, app performance improvements, shorter QA times and increased team satisfaction. Counter intuitively at the time, this was accomplished by prioritizing designer and engineer pain points instead of product inconsistencies.
      </P>

      <P>
        Inconsistent user experiences, often caused by growing teams or a growing feature set, often drive teams to invest in design systems. You’ve likely seen talks or posts that showcase the problem like this:
      </P>

      <P>   
        <img
          src="https://s3.amazonaws.com/designco-web-assets/uploads/2017/11/buzzfeed-buttons-v2-min.jpg"
          alt="Picture of the author"
        />
      </P> 
      
      <P>
        <Cheee>Background –</Cheee> This–an inconsistent user experience–was how the problem was explained during my interview at NerdWallet, and also how I’ve worked on design systems before. However, this wasn’t NerdWallet’s true issue. NerdWallet wasn’t inconsistent. Teams were structured around user journeys (e.g. finding a credit card team vs buying a house team), and users didn’t often cross these journeys within a session, so users mostly had a consistent user experience. If a user visited an article about credit cards, and decided to further research credit balances, the credit cards team owned that entire experience.
      </P>
        
      <P>
        Nerdwallet was also already profitable. They made affiliate revenue by giving generalized financial advice. Still, sound financial advice can only be so useful without knowing someone’s whole financial picture. That’s why Nerdwallet decided to build an insights-driven platform to help people manage their money. 
      </P>
      
      <P>
        Growing from money advice to financial insights isn’t really a user consistency problem. This gets into product/market fit issues, and has a different set of challenges rather than trying to resolve inconsistencies. For one, you need the freedom to break the rules and break them fast and often. You could say that this is a velocity problem. But more specifically, velocity here really means dedicating the most amount of time to figuring out what to build. To focus more on the user problem, and less about the minutia and drudgery that might eat away at that time: Engineering handoffs, spending time on layout and spacing, or how a date-picker should work.
      </P>
      
      <P>
        <Cheee>Approach –</Cheee> If we look at design systems to solve product inconsistency: You might tackle this by designing some guidelines, creating components, and making a website or something. But going back to the above, teams trying to figure out what to build don't want to follow standards. Spending time making sure you are following the rules is a tax on velocity, and that’s the opposite of what we want. We want to spend a maximum amount of time on building the right thing. Instead of building a design system meant to improve consistency, brand, or tech debt issues on consumer surfaces, we entirely prioritized team satisfaction. Not only in how designers choose these patterns, but how engineers use them. This meant frequently starting with engineering explorations before moving to design, seemingly backwards to other ways of tackling design systems. In fact, NerdWallet’s team priorities are usually this: [user, company, team, self] and we deliberately prioritized it as [self, team, company, user] 
        
        [diagram showing fixing 1000 buttons at once vs 3–6 teams implementing different but similar looking buttons] (In a larger enterprise, there might be more of an expectation that designers understand the system) For NerdWallet, the design system needed to be as user-friendly as the products it was building, and the DS had to win on its own merit, not simply from an executive mandate. Nearly everyone that’s ever worked on a platform, horizontal team, or design system will acknowledge that their users aren’t necessarily the “end-user”. Rather, their colleagues are the people using it. When presenting to leadership, however, this fact often gets deemphasized to instead talk about “end-user” impact. Sure, and to be clear, that’s what matters. But it obfuscates and discourages a different form of prioritization, which is one focused on the team. One of the most interesting gains from this flip was that it limited the impact of the “bad cop” scenario that can play out with style guide “standards.” A horizontal team needs to reign in another’s team contribution, but either doesn’t have the rappor or is interrupting the other team’s product cycle. This pattern worsens relationships and negatively impacts both teams velocity. So instead, we worked with both designers and engineers to make adoption just as important as the developed standards. As an example, when developing the typographic and grid systems (more on that here), I built a sketch plugin that would allow you to quickly use and hide/show units of space. These can not only help less visually-focused designers quickly build attractive layouts, and allows engineers to see the primitives needed to implement them in code.
      </P>

    </Grid>
  );
}
