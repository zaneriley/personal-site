import Link from "next/link";
import {H1} from "../components/typography";

export default function Home() {
  return (
    <div>
      <main>
        <H1>
          Zane Riley is a senior product designer focusing on tackling problems
          outside the screen
        </H1>

        <Link href="/case-studies/helping-people-find-healthcare">
          <a>Helping people find healthcare</a>
        </Link>

        <Link href="/case-studies/building-cohesive-products-through-design-ops">
          <a>Building cohesive products through design ops</a>
        </Link>

        <Link href="/case-studies/improving-an-ecommerce-flow">
          <a>Improving an ecommerce flow</a>
        </Link>
      </main>

      <footer />
    </div>
  );
}
