import Head from 'next/head'
import Link from 'next/link'

export default function Home() {
  return (
    <div> 
      <main>
        <h1>
          Zane Riley is a senior product designer focusing on tackling problems outside the screen
        </h1>

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
  )
}
